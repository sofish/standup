# Open-Source Readiness

Standup is prepared for open-source publication under the MIT License.

## Included Repository Files

- `LICENSE`: MIT License text with `Standup contributors` as the copyright holder.
- `README.md`: project overview, build/test commands, privacy/security summary, contribution pointer, and license pointer.
- `SECURITY.md`: vulnerability reporting process and supported-version policy.
- `CONTRIBUTING.md`: development workflow, security-reporting rule, and pull request checklist.
- `.gitignore`: excludes SwiftPM and local app build outputs.
- `docs/security.md`: implementation-level security model and release checklist.

## Release Checklist

Before publishing a tagged release:

1. Confirm generated image and icon assets can be redistributed in an open-source repository.
2. Enable GitHub Security Advisories or publish a private security contact.
3. Run `swift test`.
4. Run `./build.sh`.
5. Confirm `.build/`, `build/`, local `.app` bundles, and release zip files are not staged.
6. State signing and notarization status in GitHub release notes and keep the README install guidance aligned.

## Ongoing Maintenance Rules

- Keep `README.md`, `SECURITY.md`, and `docs/security.md` aligned whenever permissions, data handling, network behavior, or distribution practices change.
- Keep tests covering the presence and baseline content of the open-source policy files.
- Do not add third-party assets or dependencies without documenting their license compatibility.
