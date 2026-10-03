#!/usr/bin/env bash
# Builds "Reader's Night Filter.app" for Apple Silicon and Intel in one, and a .dmg
# around it. Runs on a Mac with the Xcode command-line tools.
#
#   macos/build.sh            → macos/build/readers-night_<version>_macos.dmg
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
OUT="$HERE/build"
APP="$OUT/Reader's Night Filter.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$HERE/Info.plist")"

rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

for arch in arm64 x86_64; do
    swiftc -O -swift-version 5 -target "$arch-apple-macos13.0" \
        "$HERE/ReadersNight.swift" -o "$OUT/ReadersNight-$arch"
done
lipo -create "$OUT/ReadersNight-arm64" "$OUT/ReadersNight-x86_64" -output "$APP/Contents/MacOS/ReadersNight"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

ICONSET="$OUT/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256; do
    sips -z $s $s "$ROOT/docs/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$ROOT/docs/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
sips -z 512 512 "$ROOT/docs/icon.png" --out "$ICONSET/icon_512x512.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# Ad hoc signature: on Apple Silicon an unsigned binary does not start at all.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

DMG_DIR="$OUT/dmg"
mkdir -p "$DMG_DIR"
cp -R "$APP" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
DMG="$OUT/readers-night_${VERSION}_macos.dmg"
# "hdiutil: create failed - Resource busy" happens while something still holds the
# freshly signed bundle; waiting and asking again is enough.
for try in 1 2 3; do
    if hdiutil create -volname "Reader's Night Filter" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG"; then
        echo "$DMG"
        exit 0
    fi
    sleep 15
done
exit 1
