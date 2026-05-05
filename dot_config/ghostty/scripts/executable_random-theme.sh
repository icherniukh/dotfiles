#!/bin/bash

THEMES_DIR="/Applications/Ghostty.app/Contents/Resources/ghostty/themes"

THEME_FILES=($THEMES_DIR/*)

if [ ${#THEME_FILES[@]} -eq 0 ]; then
    echo "No theme files found in $THEMES_DIR"
    exit 1
fi

RANDOM_THEME_FILE=${THEME_FILES[$RANDOM % ${#THEME_FILES[@]}]}

THEME_NAME=$(basename "$RANDOM_THEME_FILE")

ghostty --theme=$THEME_NAME

echo "  ## new theme: $THEME_NAME"

echo theme=$THEME_NAME >> ~/.config/ghostty.toml

ghostty -e reload_config
ghostty +reload_config
ghostty reload_config

