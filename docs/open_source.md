# Open-Source Readiness

Standup is prepared for open-source publication under the MIT License.

## Included Repository Files

- `LICENSE`: MIT License text with `Standup contributors` as the copyright holder.
- `README.md`: project overview, build/test commands, privacy/security summary, contribution pointer, and license pointer.
- `SECURITY.md`: vulnerability reporting process and supported-version policy.
- `CONTRIBUTING.md`: development workflow, security-reporting rule, and pull request checklist.
- `.gitignore`: excludes SwiftPM and local app build outputs.
- `docs/security.md`: implementation-level security model and release checklist.

## Pre-Publication Checklist

Before pushing to a public repository:

1. Decide whether the MIT copyright holder should remain `Standup contributors` or be changed to a person or organization.
2. Confirm generated image and icon assets can be redistributed in an open-source repository.
3. Enable GitHub Security Advisories or publish a private security contact.
4. Run `swift test`.
5. Run `./build.sh`.
6. Confirm `.build/`, `build/`, and local `.app` bundles are ignored.

## Ongoing Maintenance Rules

- Keep `README.md`, `SECURITY.md`, and `docs/security.md` aligned whenever permissions, data handling, network behavior, or distribution practices change.
- Keep tests covering the presence and baseline content of the open-source policy files.
- Do not add third-party assets or dependencies without documenting their license compatibility.
