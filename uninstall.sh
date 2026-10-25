#!/bin/bash
set -euo pipefail
LABEL=com.local.studymode
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/Study Mode.app"
echo 'Study Mode uninstalled.'
