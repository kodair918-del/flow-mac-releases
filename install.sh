#!/bin/bash
# Flow for Mac: one-step installer. Paste into the Terminal:
#   curl -fsSL https://raw.githubusercontent.com/kodair918-del/flow-mac-releases/main/install.sh | bash
# Downloads the latest build, puts it in ~/Applications, clears the download quarantine flag
# (so there is no "unidentified developer" warning) and starts it. After that Flow updates itself
# (menu bar icon > the update line).
set -euo pipefail

BASE="https://raw.githubusercontent.com/kodair918-del/flow-mac-releases/dist"
APP="Flow"
DEST="$HOME/Applications"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> Downloading the latest Flow"
curl -fsSL "$BASE/latest.json" -o "$work/latest.json"
curl -fsSL "$BASE/Flow-mac.zip" -o "$work/Flow-mac.zip"

# the zip must be the one latest.json describes
want="$(grep -o '"sha256"[^,}]*' "$work/latest.json" | sed 's/.*: *"\([0-9a-fA-F]*\)".*/\1/' | tr 'A-F' 'a-f')"
have="$(shasum -a 256 "$work/Flow-mac.zip" | cut -d' ' -f1)"
if [ -n "$want" ] && [ "$want" != "$have" ]; then
    echo "The download does not match its checksum. Wait a few minutes and run this again." >&2
    exit 1
fi

echo "==> Installing into $DEST"
pkill -x "$APP" 2>/dev/null || true
pkill -x "TaskbarLayerLab" 2>/dev/null || true   # the old name of this app
mkdir -p "$DEST"
rm -rf "$DEST/$APP.app" "$DEST/TaskbarLayerLab.app"
unzip -q "$work/Flow-mac.zip" -d "$work/unpacked"
ditto "$work/unpacked/$APP.app" "$DEST/$APP.app"
xattr -dr com.apple.quarantine "$DEST/$APP.app" 2>/dev/null || true

echo "==> Starting $APP"
open "$DEST/$APP.app"
echo "Done. The wave icon is in the menu bar."
