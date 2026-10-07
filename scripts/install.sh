#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_app_dir="$HOME/Applications/Sleep Status.app"
while IFS= read -r task_pid; do
    if [[ "$(ps -p "$task_pid" -o comm=)" == "$task_app_dir/Contents/MacOS/SleepStatus" ]]; then
        kill -TERM "$task_pid"
        for ((task_wait = 0; task_wait < 50; task_wait++)); do
            if ! kill -0 "$task_pid" 2>/dev/null; then break; fi
            sleep 0.1
        done
        if kill -0 "$task_pid" 2>/dev/null; then
            printf '%s\n' 'Existing monitor did not exit. Installation stopped.' >&2
            exit 1
        fi
    fi
done < <(pgrep -x SleepStatus || true)
mkdir -p "$HOME/Applications"
/usr/bin/ditto "$task_root/build/Sleep Status.app" "$task_app_dir"
/usr/bin/open -g "$task_app_dir"
printf '%s\n' "Started $task_app_dir"
