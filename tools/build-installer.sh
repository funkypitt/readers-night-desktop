#!/usr/bin/env bash
# Builds dist/readers-night-install.sh (the installer with its files appended) and
# dist/readers-night-browser-<version>.zip (the browser extension).
set -eu
cd "$(dirname "$0")/.."
VERSION="$(python3 -c 'import json; print(json.load(open("browser/manifest.json"))["version"])')"

python3 tools/amber.py > /dev/null
glib-compile-schemas --strict "gnome/readers-night@gallaz.ch/schemas"

mkdir -p dist
out="dist/readers-night-install.sh"
sed "s/@VERSION@/$VERSION/" install/installer.sh > "$out"
tar -cz --owner=0 --group=0 --sort=name --mtime='2026-01-01' \
    bin/readers-night icons/readers-night.svg "gnome/readers-night@gallaz.ch" plasma/readersnight \
    | base64 -w 76 >> "$out"
chmod +x "$out"

rm -f "dist/readers-night-browser-$VERSION.zip"
(cd browser && zip -qr "../dist/readers-night-browser-$VERSION.zip" . -x '.*')
ls -l dist
