#!/bin/bash
# Generate a random hex color, set it as split-divider-color, and reload
CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

COLOR=$(printf '#%02x%02x%02x' $((RANDOM % 200 + 56)) $((RANDOM % 200 + 56)) $((RANDOM % 200 + 56)))

sed -i '' "s/^split-divider-color=.*/split-divider-color=$COLOR/" "$CONFIG"

echo "Split divider → $COLOR"

osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1'
