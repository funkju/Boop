#!/bin/zsh
# Build Boop (Release) and install it to ~/Applications.
set -euo pipefail
cd "$(dirname "$0")"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"

# Resolve packages first so we can stub SwiftLint before it runs. The real
# binary crashes under the beta toolchain (sourcekitdInProc load failure).
xcodebuild -project Boop.xcodeproj -scheme Boop -derivedDataPath build \
  -resolvePackageDependencies | tail -1 || true

SWIFTLINT="build/SourcePackages/artifacts/swiftlintplugin/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint"
if [[ -f "$SWIFTLINT" ]] && ! head -1 "$SWIFTLINT" | grep -q '^#!/bin/sh'; then
  cat > "$SWIFTLINT" <<'EOF'
#!/bin/sh
# Stub: real swiftlint fails under the beta toolchain. Create the dirs the
# build plugin declares (cache path + its Output dir), then succeed.
prev=""
for arg in "$@"; do
  if [ "$prev" = "--cache-path" ]; then
    mkdir -p "$arg/Output"
  fi
  prev="$arg"
done
exit 0
EOF
  chmod +x "$SWIFTLINT"
fi

xcodebuild -project Boop.xcodeproj -scheme Boop -configuration Release \
  -derivedDataPath build -skipPackagePluginValidation \
  COMPILER_INDEX_STORE_ENABLE=NO build | grep -E "error:|BUILD" || true

APP="build/Build/Products/Release/Boop.app"
DEST="$HOME/Applications/Boop.app"

[[ -d "$APP" ]] || { echo "Build product not found at $APP"; exit 1; }

# Quit a running copy so the bundle can be swapped cleanly.
osascript -e 'tell application "Boop" to quit' 2>/dev/null || true

rm -rf "$DEST"
ditto "$APP" "$DEST"

# Deep re-sign ad-hoc so the app and its embedded frameworks agree.
codesign --force --deep --sign - "$DEST"
echo "Installed $DEST"
open "$DEST"
