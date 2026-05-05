#!/bin/bash
# Set current Ghostty tab to a random color via OSC escape sequences
# Uses iTerm2-compatible OSC 6;1;bg protocol (supported by Ghostty)

R=$((RANDOM % 200 + 56))
G=$((RANDOM % 200 + 56))
B=$((RANDOM % 200 + 56))

printf '\e]6;1;bg;red;brightness;%d\a' "$R"
printf '\e]6;1;bg;green;brightness;%d\a' "$G"
printf '\e]6;1;bg;blue;brightness;%d\a' "$B"
