# Contributing

Thanks for considering a contribution to Standup.

## Development Workflow

Use the local SwiftPM workflow:

```sh
swift test
./build.sh
open build/Standup.app
```

Keep behavior, tests, and docs in sync. UI changes should be verified in a running macOS app bundle because menu bar and overlay rendering can differ from source-level assumptions.

## Security Reports

Do not open public issues for vulnerabilities. Follow [SECURITY.md](SECURITY.md).

## Pull Request Checklist

- Add or update tests for behavior changes.
- Update `docs/` for feature, behavior, security, or release-process changes.
- Avoid committing local build outputs such as `.build/`, `build/`, or `.app` bundles.
- Document the provenance and license of any new image or generated asset.
