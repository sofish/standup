# Standup

Standup is a native macOS menu bar app that reminds you to stand up after a configurable focus period. It tracks continuous screen-session time locally, resets after a real break, and shows a full-screen glass reminder overlay when the target is reached.

## Features

- Native SwiftUI menu bar app with no external runtime dependency.
- Configurable focus target and break-reset duration.
- Local screen-session tracking via macOS idle time and display-sleep assertions.
- Full-screen reminder overlay with reset, Escape reset, auto-reset countdown, and later reminders.
- Optional Start at Login support through macOS login item APIs.

## Requirements

- macOS 13 or newer.
- Swift 5.8 or newer.

## Build And Test

```sh
swift test
./build.sh
open build/Standup.app
```

`build.sh` creates `build/Standup.app` and copies the bundled icon and animation resources into the app bundle.

## Privacy And Security

Standup is local-only in the current codebase. It does not include an app network client, telemetry, accounts, or cloud sync. It reads macOS idle and power assertion state, stores timing preferences in local user defaults, requests notification permission, and can register itself as a login item when the user enables Start at Login.

Security reporting is documented in [SECURITY.md](SECURITY.md). The implementation-level security model is documented in [docs/security.md](docs/security.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep tests and docs in sync with behavior changes.

## License

Standup is open source under the [MIT License](LICENSE).
