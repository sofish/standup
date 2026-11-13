#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

SIGNED=false
if [[ $# -gt 1 ]]; then
    echo "Usage: ./build.sh [--signed]" >&2
    exit 2
fi
case "${1:-}" in
    "") ;;
    --signed) SIGNED=true ;;
    --help|-h)
        echo "Usage: ./build.sh [--signed]"
        echo "  --signed  Sign with Developer ID and create a local ZIP (not notarized)."
        echo "  SIGNING_IDENTITY selects a certificate name or SHA-1; defaults to Developer ID Application."
        exit 0
        ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

OUTPUT_DIR="build"
if $SIGNED; then
    OUTPUT_DIR="build/signed"
    # Remove prior candidates so failed builds cannot leave a stale release ZIP.
    rm -rf "$OUTPUT_DIR"
fi

echo "🔨 Building Standup in Release mode..."
swift build -c release
BINARY_DIR="$(swift build -c release --show-bin-path)"

echo "📦 Creating Standup.app bundle..."
APP_DIR="${OUTPUT_DIR}/Standup.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MAC_OS_DIR="${CONTENTS_DIR}/MacOS"

# Recreate the app bundle structure
rm -rf "${APP_DIR}"
mkdir -p "${MAC_OS_DIR}"

# Copy binary
cp "${BINARY_DIR}/Standup" "${MAC_OS_DIR}/Standup"

# Copy Resources
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
mkdir -p "${RESOURCES_DIR}"
cp -R Resources/* "${RESOURCES_DIR}/"


# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Standup</string>
    <key>CFBundleIdentifier</key>
    <string>fun.built4.standup</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Standup</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.4</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

plutil -lint "${CONTENTS_DIR}/Info.plist"

if $SIGNED; then
    echo "🔏 Signing with Developer ID..."
    codesign --force --options runtime --timestamp \
        --sign "${SIGNING_IDENTITY:-Developer ID Application}" "$APP_DIR"
    # Apple's Developer ID Application certificate extension rejects development,
    # App Store, and ad-hoc signatures using the native requirement evaluator.
    codesign --verify --deep --strict --verbose=2 \
        --test-requirement '=anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.13] exists' \
        "$APP_DIR"

    VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${CONTENTS_DIR}/Info.plist")"
    ARCH="$(lipo -archs "${MAC_OS_DIR}/Standup")"
    case "$ARCH" in
        arm64|x86_64) ;;
        *) echo "Unsupported release architecture: $ARCH" >&2; exit 1 ;;
    esac
    ZIP_NAME="Standup-v${VERSION}-macOS-${ARCH}-signed.zip"
    ditto -c -k --keepParent "$APP_DIR" "${OUTPUT_DIR}/${ZIP_NAME}.tmp"
    mv "${OUTPUT_DIR}/${ZIP_NAME}.tmp" "${OUTPUT_DIR}/${ZIP_NAME}"
    (cd "$OUTPUT_DIR" && shasum -a 256 "$ZIP_NAME" > "${ZIP_NAME}.sha256")
    echo "✅ Signed candidate: ${OUTPUT_DIR}/${ZIP_NAME}"
    echo "Not notarized. Complete docs/release.md before public distribution."
fi

echo "✅ App successfully bundled at: ${APP_DIR}"
echo "🚀 To run: open ${APP_DIR}"
