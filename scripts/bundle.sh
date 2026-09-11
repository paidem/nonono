#!/usr/bin/env bash
# Build the release binary and wrap it in build/nonono.app (ad-hoc signed unless
# SIGN_IDENTITY is set). UNIVERSAL=1 builds arm64+x86_64.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "${UNIVERSAL:-0}" = "1" ]; then
    swift build -c release --arch arm64 --arch x86_64
    BIN=.build/apple/Products/Release/nonono
else
    swift build -c release
    BIN=.build/release/nonono
fi

APP="build/nonono.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/nonono"

VERSION="${VERSION:-0.0.0}"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>nonono</string>
    <key>CFBundleIdentifier</key><string>com.pavel.nonono</string>
    <key>CFBundleName</key><string>nonono</string>
    <key>CFBundleDisplayName</key><string>nonono</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

if [ -n "${SIGN_IDENTITY:-}" ]; then
    # Developer ID: hardened runtime + timestamp are required for notarization.
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
    codesign --force --sign - "$APP"
fi
echo "built $APP ($(lipo -archs "$APP/Contents/MacOS/nonono"), version $VERSION)"
