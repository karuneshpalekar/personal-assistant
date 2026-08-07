#!/bin/bash
# Builds a Release version and installs it to /Applications, bypassing
# Xcode's GUI entirely (Xcode 15.3 on this machine crashes with an
# uncaught NSException — +[PBXProject
# _formatForMissingPreferredProjectFormatAttribute] — reproduced across
# several different project configurations, so it's an Xcode bug, not a
# project issue; command-line builds are unaffected).
#
# Run this after making code changes to rebuild and reinstall.
set -euo pipefail
cd "$(dirname "$0")"

./generate.sh

xcodebuild -project KanbanTimeline.xcodeproj -scheme KanbanTimeline \
  -configuration Release -destination 'platform=macOS' -allowProvisioningUpdates build

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -iname 'KanbanTimeline-*' -print -quit)/Build/Products/Release/KanbanTimeline.app

rm -rf /Applications/KanbanTimeline.app
cp -R "$APP_PATH" /Applications/
xattr -dr com.apple.quarantine /Applications/KanbanTimeline.app 2>/dev/null || true

killall KanbanTimeline 2>/dev/null || true
open /Applications/KanbanTimeline.app

echo "Installed and launched /Applications/KanbanTimeline.app"
echo "Look for the grid icon in your menu bar."
