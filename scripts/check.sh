#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_app_dir="$task_root/build/Sleep Status.app"
/usr/bin/plutil -lint "$task_app_dir/Contents/Info.plist"
/usr/bin/codesign --verify --strict "$task_app_dir"
test -x "$task_app_dir/Contents/MacOS/SleepStatus"
printf '%s\n' 'App bundle verified.'
