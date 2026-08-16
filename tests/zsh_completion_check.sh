#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/home" "$tmpdir/cache/zsh"
: >"$tmpdir/home/.zsh_plugins.txt"
: >"$tmpdir/cache/zsh/plugins.zsh"

TERM=xterm-256color \
HOME="$tmpdir/home" \
XDG_CACHE_HOME="$tmpdir/cache" \
ZSH_CACHE_DIR="$tmpdir/cache/zsh" \
zsh -fic "
  autoload -Uz compinit
  compinit -d \"\$ZSH_CACHE_DIR/zcompdump-\$ZSH_VERSION\"
"

TERM=xterm-256color \
HOME="$tmpdir/home" \
XDG_CACHE_HOME="$tmpdir/cache" \
ZSH_CACHE_DIR="$tmpdir/cache/zsh" \
zsh -fic "
  source '$repo_root/dot_config/zsh/env.zsh'
  source '$repo_root/dot_config/zsh/plugins.zsh'
  [[ \${+functions[compinit]} -eq 1 ]]
  [[ \${+functions[_main_complete]} -eq 1 ]]
  [[ \${+functions[compdef]} -eq 1 ]]
  [[ \${+_comps[git]} -eq 1 ]]
  [[ \${+_comps[ssh]} -eq 1 ]]
  [[ \${+_comps[bd]} -eq 1 ]]
  [[ -f \"\$ZSH_CACHE_DIR/site-functions/_bd\" ]]
"
