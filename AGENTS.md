# Sleep Status

A small macOS menu-bar utility that shows the actual `SleepDisabled` setting. It observes power state and never changes sleep settings.

## Structure

```text
Sources/SleepStatus/   AppKit monitor
Resources/Info.plist   App bundle metadata
scripts/              Build, bundle validation and local installation
docs/                 Shared usage and development documentation
```

## Development

Swift + AppKit + IOKit; no third-party packages. Run mise tasks, which select the installed Apple toolchain with `xcrun`.

```sh
mise run build
mise run check
mise run install
```

Read `docs/development.md` before packaging, installing or investigating diagnostic logs. Keep English and Japanese READMEs aligned. Runtime observations and machine-specific investigation notes must stay out of Git.

## Verification

Validate the bundle with `mise run check`. After changing runtime behavior, verify the installed app, OS state and sampling interval. Do not equate a valid bundle with visually verified UI. Preserve the current 1-minute interval unless the user asks to change it.
