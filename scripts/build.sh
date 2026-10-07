#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_root"
/usr/bin/xcrun swift build --configuration release
task_bin_dir="$(/usr/bin/xcrun swift build --configuration release --show-bin-path)"
task_app_dir="$task_root/build/Sleep Status.app"
mkdir -p "$task_app_dir/Contents/MacOS"
cp "$task_root/Resources/Info.plist" "$task_app_dir/Contents/Info.plist"
cp "$task_bin_dir/SleepStatus" "$task_app_dir/Contents/MacOS/SleepStatus"
/usr/bin/codesign --force --sign - "$task_app_dir"
