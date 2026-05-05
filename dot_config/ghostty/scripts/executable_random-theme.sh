#!/bin/bash

THEMES_DIR="/Applications/Ghostty.app/Contents/Resources/ghostty/themes"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

THEME_FILES=($THEMES_DIR/*)

if [ ${#THEME_FILES[@]} -eq 0 ]; then
    echo "No theme files found in $THEMES_DIR"
    exit 1
fi

RANDOM_THEME_FILE=${THEME_FILES[$RANDOM % ${#THEME_FILES[@]}]}

THEME_NAME=$(basename "$RANDOM_THEME_FILE")

ghostty --theme=$THEME_NAME

echo "  ## new theme: $THEME_NAME"

mkdir -p "$(dirname "$CONFIG_FILE")"
if grep -q '^theme=' "$CONFIG_FILE" 2>/dev/null; then
    sed -i '' "s/^theme=.*/theme=$THEME_NAME/" "$CONFIG_FILE"
else
    printf '\ntheme=%s\n' "$THEME_NAME" >> "$CONFIG_FILE"
fi

ghostty +reload_config
