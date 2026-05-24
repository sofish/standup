#!/bin/bash
set -e

# Navigate to project directory
cd "$(dirname "$0")"

echo "🔨 Building Standup in Release mode..."
swift build -c release

echo "📦 Creating Standup.app bundle..."
APP_DIR="build/Standup.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MAC_OS_DIR="${CONTENTS_DIR}/MacOS"

# Recreate the app bundle structure
rm -rf "${APP_DIR}"
mkdir -p "${MAC_OS_DIR}"

# Copy binary
cp ".build/release/Standup" "${MAC_OS_DIR}/Standup"

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
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ App successfully bundled at: build/Standup.app"
echo "🚀 To run: open build/Standup.app"
