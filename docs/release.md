# Signed macOS Releases

Standup uses SwiftPM and a single native app executable. No new app entitlements or provisioning profile are required for its current capabilities. The bundle identifier remains `fun.built4.standup` so preferences and login-item identity stay associated with the app. Moving from ad-hoc to Developer ID signing changes its designated requirement; verify notification permission and Start at Login during upgrade acceptance.

## Source And Authorization

Local builds and signing checks do not publish a release. Commit/push, notarization uploads, and GitHub publication require authorization for those actions. A local signed candidate can be tested in a worktree; rebuild release artifacts after all in-scope source changes are committed, merged into the live origin primary branch, and pushed. Verify fresh remote-primary containment and local-primary alignment before building a distributable artifact.

Version 1.0.4 (build 5) is the next signing release. It does not alter the existing ad-hoc signed, unnotarized ZIPs through v1.0.3. Do not claim the next release is notarized until its own Apple receipt and final archive checks pass.

## Prepare A Signed Candidate

Use macOS with Xcode selected by `xcode-select`, Python 3.8+ for packaging tests, and a valid Developer ID Application certificate plus private key in the current user's Keychain. Inspect available identities without exporting keys:

```sh
security find-identity -v -p codesigning
swift test
python3 -m unittest discover -s Tests/ReleaseBuildTests -v
./build.sh --signed
```

The build uses the host architecture, preserving the existing arm64 release channel on Apple silicon. An Intel build produces an `x86_64` ZIP; neither is universal. `SIGNING_IDENTITY` can select a certificate by name or SHA-1, without changing the certificate type required by verification. Ambiguous or missing identities fail instead of falling back to ad-hoc signing.

The outputs are `build/signed/Standup.app`, `Standup-v1.0.4-macOS-<arch>-signed.zip`, and a matching `.zip.sha256` file. Each signed build clears that generated directory; preserve pending submission receipts before rebuilding. The ordinary `./build.sh` workflow still creates `build/Standup.app` for local development.

PiPi's `.pipi/acceptance.json` runs the Swift tests, packaging regression tests, and shell/diff checks with source-bound receipts and a documentation/simplify review. It does not sign, upload, or publish. Real certificate, launch, notarization, and destination checks remain separate release evidence.

Verify bundle version/build, identifier, minimum macOS version, resources, and architecture. Check the signature for Developer ID Application authority, expected team, Hardened Runtime, and secure timestamp:

```sh
plutil -p build/signed/Standup.app/Contents/Info.plist
lipo -archs build/signed/Standup.app/Contents/MacOS/Standup
codesign --display --verbose=4 build/signed/Standup.app
codesign --verify --deep --strict --verbose=2 build/signed/Standup.app
(cd build/signed && shasum -a 256 -c *.zip.sha256)
```

`--signed` contacts Apple's timestamp service, but does not submit the app for notarization. A signed candidate can still be rejected by Gatekeeper until notarization succeeds. Do not distribute the `-signed.zip` candidate or ask users to remove quarantine for the new release.

## Notarize After Release Authorization

Use an existing authorized notarytool Keychain profile. If a profile needs to be created, run `xcrun notarytool store-credentials "standup-notary"` interactively; enter credentials only in the native secure prompts. Never place passwords or private API keys in source, command arguments, logs, or artifacts.

An existing authorized App Store Connect API key is also supported: replace `--keychain-profile "standup-notary"` in the commands below with `--key /path/to/AuthKey_KEY_ID.p8 --key-id KEY_ID --issuer ISSUER_ID`. The `--key` argument references the native private-key file; never pass its contents or copy the key into the repository. Omit `--issuer` for an individual API key, as required by notarytool.

After rebuilding from published source, submit once and save its ID before waiting. The example below assumes an arm64 build; substitute `x86_64` for an Intel build. Keep the original uploaded ZIP and receipts together. If a submission already exists or an upload result is uncertain, reconcile its history/ID first; do not blindly submit again.

```sh
set -euo pipefail
xcrun notarytool submit build/signed/Standup-v1.0.4-macOS-arm64-signed.zip \
    --keychain-profile "standup-notary" --output-format json \
    > build/notarization-submission.json
STANDUP_SUBMISSION_ID="$(plutil -extract id raw -o - build/notarization-submission.json)"
xcrun notarytool wait "$STANDUP_SUBMISSION_ID" \
    --keychain-profile "standup-notary" --output-format json \
    > build/notarization-result.json
xcrun notarytool log "$STANDUP_SUBMISSION_ID" \
    --keychain-profile "standup-notary" build/notarization-log.json
test "$(plutil -extract status raw -o - build/notarization-result.json)" = "Accepted"
```

Review `notarization-log.json` even after acceptance. If waiting fails or is interrupted, recover with `notarytool info`, `wait`, or `log` using the saved ID. A timeout does not cancel Apple's processing. An invalid result blocks publication; inspect its log and fix the reported issue before considering another upload.

## Staple And Package The Distribution

ZIPs cannot receive a stapled ticket. Staple the accepted app first, then create a fresh distribution ZIP in a separate directory. Do not re-sign or change the app after notarization.

```sh
set -euo pipefail
xcrun stapler staple build/signed/Standup.app
xcrun stapler validate build/signed/Standup.app
codesign --verify --deep --strict --verbose=2 build/signed/Standup.app
spctl --assess --type execute --verbose=4 build/signed/Standup.app
mkdir -p build/notarized
ditto -c -k --keepParent build/signed/Standup.app \
    build/notarized/Standup-v1.0.4-macOS-arm64.zip
(cd build/notarized && shasum -a 256 Standup-v1.0.4-macOS-arm64.zip \
    > Standup-v1.0.4-macOS-arm64.zip.sha256)
rm -rf build/notarized/verify
ditto -x -k build/notarized/Standup-v1.0.4-macOS-arm64.zip build/notarized/verify
codesign --verify --deep --strict --verbose=2 build/notarized/verify/Standup.app
xcrun stapler validate build/notarized/verify/Standup.app
spctl --assess --type execute --verbose=4 build/notarized/verify/Standup.app
```

## Release Acceptance And Recovery

- Keep the source commit, test logs, original submitted ZIP checksum, Apple submission ID/result/log, signature details, and final stapled ZIP checksum as release evidence.
- Launch the signed app on the build Mac and verify the menu, reminder/reset behavior, and notification permission. Test Start at Login explicitly, restoring its previous setting afterward.
- Test the final download on a Gatekeeper-enabled Mac, preferably a different Mac/user from development. Preserve download quarantine. Verify normal first launch, resources, reminder/reset behavior, permissions, and upgrade from v1.0.3 without clearing preferences. No quarantine removal command is part of the new release acceptance.
- Publish only the final notarized ZIP and its checksum after authorization. Point the new tag at the verified pushed primary commit. State the supported architecture and actual signing/notarization status; verify the uploaded asset's checksum matches the local final archive.
- Preserve prior releases and signing identity. If verification fails, stop publication and leave the previous release available; fix and rebuild under a new version if any published bytes change. Never silently replace an existing release artifact or reuse an unknown notarization submission.

## Apple References

- [Creating distribution-signed code for macOS](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac): use Developer ID Application, Hardened Runtime, and secure timestamps; avoid `--deep` when signing.
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution): a Developer ID signature and a successful notarization are separate requirements.
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow): use Keychain profiles and notarytool, retain submission IDs/logs, and repackage after stapling the app.
