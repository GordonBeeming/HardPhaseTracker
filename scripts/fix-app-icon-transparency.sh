#!/bin/bash
set -e

# Fix App Icon Transparency
# Apple requires the 1024x1024 marketing icon to have NO transparency/alpha channel

cd "$(dirname "$0")/.."

ICON_PATH="HardPhaseTracker/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-ios-marketing-1024x1024-1x.png"

echo "Fixing app icon transparency..."
echo "Icon path: $ICON_PATH"

# Use sips (built-in macOS tool) to remove alpha channel and flatten to white background
sips -s format png \
     -s hasAlpha no \
     --setProperty formatOptions 70 \
     "$ICON_PATH" \
     --out "${ICON_PATH}.tmp"

# Replace original with fixed version
mv "${ICON_PATH}.tmp" "$ICON_PATH"

echo "✅ App icon transparency fixed"
echo ""
echo "Verification:"
sips -g hasAlpha "$ICON_PATH"
