#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$HOME/Applications/Study Mode.app"
EXEC_DIR="$APP_DIR/Contents/MacOS"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/com.local.studymode.plist"
LABEL="com.local.studymode"
UID_NOW="$(id -u)"

if ! command -v swiftc >/dev/null 2>&1; then
  echo 'Swift compiler not found. Install Apple Command Line Tools: xcode-select --install' >&2
  exit 1
fi
mkdir -p "$EXEC_DIR" "$PLIST_DIR"
echo 'Compiling Study Mode for this Mac...'
swiftc -O "$HERE/StudyMode.swift" -framework AppKit -framework CoreAudio -o "$EXEC_DIR/StudyMode"
cat > "$APP_DIR/Contents/Info.plist" <<'PLISTINFO'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.local.studymode</string>
<key>CFBundleName</key><string>Study Mode</string>
<key>CFBundleExecutable</key><string>StudyMode</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLISTINFO
launchctl bootout "gui/$UID_NOW/$LABEL" 2>/dev/null || true
cat > "$PLIST" <<PLISTXML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array><string>$EXEC_DIR/StudyMode</string></array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
<key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PLISTXML
plutil -lint "$PLIST" >/dev/null
launchctl bootstrap "gui/$UID_NOW" "$PLIST"
launchctl kickstart -k "gui/$UID_NOW/$LABEL"
echo 'Installed! Look for the headphones symbol in your macOS menu bar.'
echo 'It will launch automatically each time you log in.'
