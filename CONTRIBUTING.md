# Contributing

Thanks for considering a contribution to Standup.

## Development Workflow

Use the local SwiftPM workflow:

```sh
swift test
python3 -m unittest discover -s Tests/ReleaseBuildTests -v
./build.sh
open build/Standup.app
```

Keep behavior, tests, and docs in sync. UI changes should be verified in a running macOS app bundle because menu bar and overlay rendering can differ from source-level assumptions.

The release-build tests require Python 3.8+ and macOS packaging tools. They exercise the real build script with isolated compiler/signing stubs, including signing failures, ZIP contents, and checksums; no signing credentials or notarization uploads are used. Real Developer ID verification remains a separate release acceptance check in [docs/release.md](docs/release.md).

## Security Reports

Do not open public issues for vulnerabilities. Follow [SECURITY.md](SECURITY.md).

## Pull Request Checklist

- Add or update tests for behavior changes.
- Update `docs/` for feature, behavior, security, or release-process changes.
- Avoid committing local build outputs such as `.build/`, `build/`, or `.app` bundles.
- Document the provenance and license of any new image or generated asset.
