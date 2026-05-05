#!/usr/bin/env zsh
# Symlink scripts from ~/.scripts into ~/.local/bin
scripts_dir="$HOME/.scripts"
bin_dir="$HOME/.local/bin"
mkdir -p "$bin_dir"
for f in "$scripts_dir"/*; do
  if [[ -f "$f" && -x "$f" ]]; then
    ln -sf "$f" "$bin_dir/$(basename "$f")"
  fi
done
