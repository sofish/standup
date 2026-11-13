# Standup

Standup is a native macOS menu bar app that reminds you to stand up after a configurable focus period. It tracks continuous screen-session time locally, resets when the screen sleeps, the screen locks or unlocks, or you reset manually, and shows a full-screen glass reminder overlay when the target is reached.

## Features

- Native SwiftUI menu bar app with no external runtime dependency.
- Configurable focus target.
- Local screen-session tracking that keeps counting while the user session stays awake.
- Local debug log for state transitions at `~/Library/Logs/Standup/standup.log`.
- Full-screen reminder overlay with reset, Escape reset, auto-reset countdown, and later reminders.
- Optional Start at Login support through macOS login item APIs.

## Requirements

- macOS 13 or newer.
- Swift 5.8 or newer.

## Build And Test

```sh
swift test
python3 -m unittest discover -s Tests/ReleaseBuildTests -v
./build.sh
open build/Standup.app
```

`build.sh` creates `build/Standup.app` and copies the bundled icon and animation resources into the app bundle.

## Signed Builds

```sh
./build.sh --signed
```

This creates a Developer ID signed app, a ZIP, and its SHA-256 checksum in `build/signed/`. It uses Hardened Runtime and a secure timestamp, and stops if signing or Developer ID verification fails. A valid Developer ID Application certificate and its private key must be available in the current user's Keychain. Set `SIGNING_IDENTITY` to select a certificate name or SHA-1 when needed.

The ZIP targets the build Mac's architecture (`arm64` or `x86_64`). It is a **local candidate, not notarized or ready for public distribution**. Follow [docs/release.md](docs/release.md) for source publication, notarization, ticket stapling, and release acceptance. The signing step contacts Apple's timestamp service; it does not upload the app for notarization or publish a GitHub release.

## Install Release ZIPs

For a notarized release, verify the ZIP against its published `.sha256` file, expand it, move `Standup.app` into `/Applications`, and open it normally. The release notes identify the supported architecture and the signing/notarization status of that specific download.

### Legacy Releases

GitHub release ZIPs through v1.0.3 are ad-hoc signed development builds. They are not Developer ID signed or notarized, so macOS Gatekeeper may block the first launch after download. The v1.0.4 signing workflow does not change those existing downloads.

After confirming that the ZIP came from the project release page and that its checksum matches the release notes, technical users can install the app into `/Applications` and remove the download quarantine attribute:

```sh
sudo xattr -dr com.apple.quarantine /Applications/Standup.app
open /Applications/Standup.app
```

Future signed releases must complete Developer ID signing and notarization before publication. They should launch through normal macOS Gatekeeper checks without removing quarantine manually.

## Privacy And Security

Standup is local-only in the current codebase. It does not include an app network client, telemetry, accounts, or cloud sync. It reads macOS idle and power assertion state to distinguish recent input from quiet screen time, stores the target timing preference in local user defaults, writes a small rotating debug log on the Mac, requests notification permission, and can register itself as a login item when the user enables Start at Login.

Security reporting is documented in [SECURITY.md](SECURITY.md). The implementation-level security model is documented in [docs/security.md](docs/security.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep tests and docs in sync with behavior changes.

## License

Standup is open source under the [MIT License](LICENSE).
