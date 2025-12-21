#!/usr/bin/env zsh

paths=$(yazi --chooser-file=/dev/stdout | while read -r line; do printf "%q " "$line"; done)

if [[ -n "$paths" ]]; then
    zellij action toggle-floating-panes
    zellij action write 27 # send <Escape> key
    zellij action write-chars ":$1 $paths"
    zellij action write 13 # send <Enter> key
else
    zellij action toggle-floating-panes
fi
