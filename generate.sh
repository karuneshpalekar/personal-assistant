#!/bin/bash
# Regenerates KanbanTimeline.xcodeproj from project.yml.
#
# xcodegen writes objectVersion=77 (the Xcode 16+ project format), which
# crashes Xcode 15.x the moment you open Signing & Capabilities
# (+[PBXProject _formatForMissingPreferredProjectFormatAttribute]:
# unrecognized selector). We don't use any object types that require the
# newer format, so we downgrade it to 56 (Xcode 14/15's format) after
# generating.
set -euo pipefail
cd "$(dirname "$0")"

xcodegen generate
sed -i '' 's/objectVersion = 77;/objectVersion = 56;/' KanbanTimeline.xcodeproj/project.pbxproj

echo "Generated KanbanTimeline.xcodeproj (objectVersion downgraded for Xcode 15.x compatibility)."
