# Security Policy

## Supported Versions

Until the project publishes tagged releases, only the current default branch or current source snapshot is supported for security fixes. After public releases begin, this table should be updated with the actively supported release lines.

| Version | Supported |
| --- | --- |
| Current source | Yes |
| Older untagged builds | No |

## Reporting A Vulnerability

Please do not file public issues for security vulnerabilities.

Use GitHub Security Advisories for this repository when available. If advisories are not enabled yet, contact the repository maintainer through the repository owner's published private contact channel and include:

- Affected version or commit.
- macOS version and architecture.
- Reproduction steps.
- Expected and actual behavior.
- Any proof-of-concept code, logs, screenshots, or crash reports that help confirm impact.

The project will acknowledge valid reports on a best-effort basis, investigate impact, prepare a fix, and coordinate disclosure once a patched version or mitigation is available.

## Current Security Model

Standup is a local-only macOS menu bar app in the current source tree:

- No app network client, telemetry, accounts, or cloud sync.
- Reads macOS idle time through IOKit `HIDIdleTime`.
- Reads display-sleep assertions through `IOPMCopyAssertionsStatus` so meetings and video playback can count as active time.
- Stores timing preferences locally through SwiftUI `AppStorage` / user defaults.
- Requests notification permission for reminders.
- Registers or unregisters a login item through `SMAppService.mainApp` only when the user toggles Start at Login.

Public binary releases should be signed and notarized before broad distribution. Source builds created with `./build.sh` are local development builds.
