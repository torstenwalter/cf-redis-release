#!/bin/bash

set -e

log_dir=/var/vcap/sys/log/cf-redis-broker

disable_process_watcher() {
    echo "`date +%c` - Disabling process watcher" >> ${log_dir}/drain.log 2>&1

    process_watcher_pidfile="/var/vcap/sys/run/cf-redis-broker/process-watcher.pid"

    if [ -f $process_watcher_pidfile ]
    then
      process_watcher_pid=`cat $process_watcher_pidfile`
      set +e
        kill -USR1 $process_watcher_pid
      set -e
    fi

    sleep 1
}

echo "`date +%c` - Starting drain" >> ${log_dir}/drain.log 2>&1

disable_process_watcher

set +e
    /sbin/start-stop-daemon -n redis-server --retry TERM/600  --oknodo  --stop >> ${log_dir}/drain.log 2>&1
    exit_status=$?
set -e

case "$exit_status" in
    0)
        echo "$(date): All redis-servers shutdown" >> ${log_dir}/drain.log 2>&1
        ;;
    2)
        echo "$(date): Redis took more than ${retry_strategy} seconds to exit" >> ${log_dir}/drain.log 2>&1
        exit 1
        ;;
    *)
        echo "$(date): Failed to exit with start-stop-daemon exit_status: ${exit_status}" >> ${log_dir}/drain.log 2>&1
        exit 1
esac

echo 0
exit 0
