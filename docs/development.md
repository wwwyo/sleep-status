# Development

Run from the repository root:

```sh
mise trust
mise run check
mise run install
```

`build` compiles a release executable with Swift Package Manager and packages an ad-hoc-signed app in `build/Sleep Status.app`. `check` validates the app bundle and signature. `install` replaces only this monitor in `~/Applications` and starts it in the background.

Build tasks run through mise and invoke Apple Swift with `xcrun` because AppKit and IOKit depend on the installed Apple SDK. No compiler is downloaded and there are no third-party package dependencies. The source uses Swift 5 language mode and targets macOS 13 or later. The current local build was verified with Apple Swift 6.4 on macOS 27; older macOS versions have not been tested.

## Diagnostics

Local observations are stored in `~/Library/Application Support/SleepStatus/observations.jsonl`. These files are runtime data, not repository content. The menu has an action to open the log.

Each record includes the timestamp (UTC), `SleepDisabled`, lid state, power source, Amphetamine PID and time since the previous probe. Logs rotate at 5 MB and retain one previous file.

The monitor can reveal when the OS setting changes or Amphetamine restarts. It does not identify which process changed the setting, and minute-long sampling can miss shorter changes. `SleepDisabled = 0` does not prove that the machine will sleep: other sleep assertions and external-display conditions also matter.

To verify the installed app, compare its status with `pmset -g` and inspect the newest observation. While awake and without manual refresh, successive periodic probes should be approximately 60 seconds apart; launch, wake and manual refresh can add extra probes. GUI visibility requires a separate visual check; bundle validation alone does not verify the menu's appearance.
