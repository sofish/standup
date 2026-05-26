# Security Model

This document describes the security and privacy posture of the current Standup source tree.

## Local-Only Boundary

Standup currently has no app network client, telemetry, accounts, cloud sync, or remote configuration. The app runs as a local macOS menu bar utility and keeps timing preferences on the user's Mac.

Current boundary summary:

- No app network client.
- No telemetry.
- No accounts.
- No cloud sync.
- No remote configuration.

If network behavior is added later, this document, `README.md`, and `SECURITY.md` must be updated in the same change.

## macOS Capabilities Used

- IOKit `HIDIdleTime` reads elapsed time since physical keyboard or pointer input so the UI can distinguish recent input from quiet screen time.
- `IOPMCopyAssertionsStatus` checks whether the system is preventing display sleep, which keeps videos, meetings, and presentations classified as active screen time.
- `NSWorkspace` screen sleep/session notifications and distributed screen lock/unlock notifications reset the current session when the display sleeps, the screen locks/unlocks, or the user session resigns active.
- `UNUserNotificationCenter` requests notification permission and delivers stand-up reminders.
- `SMAppService.mainApp` registers or unregisters Start at Login only when the user toggles that setting.
- SwiftUI `AppStorage` stores the target timing preference in local user defaults.
- `LocalDebugLog` writes diagnostic state-transition events to `~/Library/Logs/Standup/standup.log`.

## Data Handling

The app does not collect, transmit, or persist detailed activity logs. It maintains the current session counters in memory, persists only the user-selected target timing setting through user defaults, and writes a small local diagnostic log for debugging reminder behavior.

The debug log is local to the Mac, rotates at 512 KB, and records only app state transitions such as tracker start, quiet-input detection, target changes, snooze, reminder trigger, reset reason, lock state, and notification authorization or delivery failures. It does not record keyboard content, window titles, app names, documents, websites, screenshots, or network data.

## Release Security Checklist

Before publishing a public release:

1. Run `swift test`.
2. Run `./build.sh` and verify the app bundle metadata.
3. Confirm no local build outputs are staged.
4. Confirm generated image assets have acceptable provenance for open-source distribution.
5. Enable GitHub Security Advisories or provide another private vulnerability reporting channel.
6. Sign and notarize public binary builds if distributing prebuilt apps.

Current public release packages are ad-hoc signed development zip archives, not Developer ID signed or notarized. Release notes must state this status so users understand the macOS Gatekeeper tradeoff before downloading.
