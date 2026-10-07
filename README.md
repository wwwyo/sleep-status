# Sleep Status

[日本語](docs/README.ja.md)

See whether macOS has actually disabled system sleep before leaving an agent or another long job running. Sleep Status reads the OS setting and shows it in the menu bar, even if a keep-awake app reports a different state.

- 🟢 **スリープ無効** — system sleep is disabled (`SleepDisabled = 1`).
- ⚪ **防止OFF** — this setting is off; other apps or normal clamshell conditions may still keep the Mac awake.
- ❓ **確認失敗** — the OS setting could not be read.

The monitor checks once a minute, on launch and after wake. Click **今すぐ確認** to refresh immediately. It observes the setting; it does not change it. Screen lock and display sleep are separate.

## Install from source

Requires macOS 13 or later and Apple Swift 5.9 or later (Xcode or Command Line Tools).

```sh
git clone https://github.com/wwwyo/sleep-status.git
cd sleep-status
bash scripts/build.sh
bash scripts/check.sh
bash scripts/install.sh
```

The app starts from `~/Applications/Sleep Status.app`. Login auto-start is not configured; reopen the app after logging in. Choose **終了（監視だけ停止）** to quit.

[Development and diagnostic logs](docs/development.md)

## License

[MIT](LICENSE).
