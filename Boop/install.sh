#!/bin/zsh
# Build Boop (Release) and install it to ~/Applications.
set -euo pipefail
cd "$(dirname "$0")"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
xcodebuild -project Boop.xcodeproj -scheme Boop -configuration Release \
  -derivedDataPath build build | grep -E "error:|BUILD" || true

APP="build/Build/Products/Release/Boop.app"
DEST="$HOME/Applications/Boop.app"

[[ -d "$APP" ]] || { echo "Build product not found at $APP"; exit 1; }

# Quit a running copy so the bundle can be swapped cleanly.
osascript -e 'tell application "Boop" to quit' 2>/dev/null || true

rm -rf "$DEST"
ditto "$APP" "$DEST"
echo "Installed $DEST"
open "$DEST"
