#!/usr/bin/env zsh

paths=$(yazi --chooser-file=/dev/stdout | while read -r line; do printf "%q " "$line"; done)

if [[ -n "$paths" ]]; then
    wezterm cli activate-pane-direction --pane-id=${WEZTERM_PANE} down
    wezterm cli send-text --pane-id=${WEZTERM_PANE} --no-paste $'\e' # send <Escape> key
    wezterm cli send-text --pane-id=${WEZTERM_PANE} --no-paste ":$1 $paths"
    wezterm cli send-text --pane-id=${WEZTERM_PANE} --no-paste $'\r' # send <Enter> key
else
    wezterm cli activate-pane-direction --pane-id=${WEZTERM_PANE} up
fi
