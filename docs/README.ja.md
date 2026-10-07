# Sleep Status

[English](../README.md)

AI agent などの長い処理を放置する前に、macOS が本当にスリープを無効にしているかメニューバーで確認できます。スリープ防止アプリの表示と OS の状態が食い違っていても、OS 側の値を表示します。

- 🟢 **スリープ無効** — 本体のスリープが無効 (`SleepDisabled = 1`)。
- ⚪ **防止OFF** — この設定は無効。他のアプリや通常のクラムシェル動作で起動を維持する場合はあります。
- ❓ **確認失敗** — OS の値を取得できない状態。

起動時・復帰時・1分ごとに確認します。「今すぐ確認」をクリックすると即時更新できます。状態を観測するアプリで、スリープ設定は変更しません。画面ロックと画面の消灯は別です。

## ソースから導入

macOS 13 以降と Apple Swift 5.9 以降（Xcode または Command Line Tools）が必要です。

```sh
git clone https://github.com/wwwyo/sleep-status.git
cd sleep-status
bash scripts/build.sh
bash scripts/check.sh
bash scripts/install.sh
```

`~/Applications/Sleep Status.app` にインストールして起動します。ログイン時の自動起動は未設定なので、再ログイン後はアプリを開いてください。「終了（監視だけ停止）」で終了します。

[開発と診断ログ](development.md)

## ライセンス

[MIT](../LICENSE)。
