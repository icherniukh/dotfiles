#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run after installers too: this catches a second compinit appended to ~/.zshrc,
# which isolated configuration tests cannot see.
if [[ "${1:-}" == --live ]]; then
  zsh -lic '
    set -e
    for tool in codex hunk jj mise uv; do
      whence -p "$tool" >/dev/null || continue
      [[ ${_comps[$tool]-} == _$tool ]]
    done
    [[ ${_comps[claude]-} == _gnu_generic ]]
    [[ ${_comps[composio]-} == _gnu_generic ]]
    if whence -p carapace >/dev/null; then
      [[ ${_comps[bun]-} == _carapace_completer ]]
    fi
    print "Live completion registrations: PASS"
  '
  exit
fi
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export TERM=xterm-256color HOME="$tmpdir/home" ZDOTDIR="$tmpdir/home"
export XDG_CONFIG_HOME="$tmpdir/config" XDG_CACHE_HOME="$tmpdir/cache"
export XDG_STATE_HOME="$tmpdir/state" XDG_DATA_HOME="$tmpdir/data"
export XDG_RUNTIME_DIR="$tmpdir/run" TMPDIR="$tmpdir/tmp"
export ZSH_CACHE_DIR="$tmpdir/cache/zsh" HISTFILE="$tmpdir/state/zsh/history"
export ANTIDOTE_HOME="$tmpdir/data/antidote"
unset FPATH ZSH_COMPDUMP TERM_PROGRAM GHOSTTY_RESOURCES_DIR
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$ZSH_CACHE_DIR" "$XDG_STATE_HOME" \
  "$XDG_DATA_HOME" "$XDG_RUNTIME_DIR" "$TMPDIR"
: >"$HOME/.zsh_plugins.txt"
: >"$ZSH_CACHE_DIR/plugins.zsh"

zsh -fic "
  autoload -Uz compinit
  compinit -d \"\$ZSH_CACHE_DIR/zcompdump-\$ZSH_VERSION\"
"

zsh -fic "
  set -e
  source '$repo_root/dot_config/zsh/env.zsh'
  ZSH_CONFIG_DIR='$repo_root/dot_config/zsh'
  source '$repo_root/dot_config/zsh/plugins.zsh'
  [[ \${+functions[compinit]} -eq 1 ]]
  [[ \${+functions[_main_complete]} -eq 1 ]]
  [[ \${+functions[compdef]} -eq 1 ]]
  [[ \${+_comps[git]} -eq 1 ]]
  [[ \${+_comps[ssh]} -eq 1 ]]
  [[ \${+_comps[bd]} -eq 1 ]]
  [[ -f \"\$ZSH_CACHE_DIR/site-functions/_bd\" ]]
  [[ \${_comps[claude]-} == _gnu_generic ]]
  [[ \${_comps[composio]-} == _gnu_generic ]]
  for tool in codex hunk jj mise uv; do
    whence -p \"\$tool\" >/dev/null || continue
    [[ \${_comps[\$tool]-} == _\$tool ]]
  done
  print 'Managed completion registrations: PASS'
"
