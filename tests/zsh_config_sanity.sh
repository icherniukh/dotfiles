#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

plugin_list="$repo_root/dot_zsh_plugins.txt"
plugins_file="$repo_root/dot_config/zsh/plugins.zsh"
aliases_file="$repo_root/dot_config/zsh/aliases.zsh"
gitconfig_file="$repo_root/dot_gitconfig"
paths_file="$repo_root/dot_config/zsh/paths.zsh"
zshrc_file="$repo_root/dot_zshrc"

[[ -f "$plugin_list" ]] || {
  echo "missing managed plugin list: $plugin_list" >&2
  exit 1
}

if rg -n 'code-stats|codestats' "$plugin_list" "$plugins_file" >/dev/null; then
  echo "CodeStats references must be removed from managed zsh plugin config" >&2
  exit 1
fi

if ! rg -n 'helper = !gh auth git-credential' "$gitconfig_file" >/dev/null; then
  echo "git credential helper should use portable gh invocation" >&2
  exit 1
fi

if rg -n '/usr/bin/gh|/opt/homebrew/bin/gh' "$gitconfig_file" >/dev/null; then
  echo "git credential helper should not hardcode gh path" >&2
  exit 1
fi

if rg -n '_helix_remote_exec|HELIX_REMOTE_THEME|HELIX_SSH_THEME|helix_themed|hx\\(\\)|helix\\(\\)' "$aliases_file" >/dev/null; then
  echo "aliases.zsh should not carry SSH-specific Helix wrappers" >&2
  exit 1
fi

if ! rg -n 'bd completion zsh' "$plugins_file" >/dev/null; then
  echo "bd zsh completion should be generated from the installed bd binary" >&2
  exit 1
fi

if rg -n '(PATH=.*|path[+]?[=(].*)(venvs/transcribe/bin|\.claude/(agents|context|templates))' "$paths_file" "$zshrc_file" >/dev/null; then
  echo "PATH must not add project virtualenvs or Claude data directories" >&2
  exit 1
fi

if rg -n 'PATH=.*\.(codeium|antigravity|opencode|bun)' "$paths_file" >/dev/null; then
  echo "optional tool directories must be added to PATH conditionally" >&2
  exit 1
fi

if ! rg -n "alias tx='tmuxinator'" "$aliases_file" >/dev/null; then
  echo "tx should remain the short alias for tmuxinator" >&2
  exit 1
fi

if rg -n "alias tmuxinator='tx'" "$aliases_file" >/dev/null; then
  echo "the tmuxinator alias direction is reversed" >&2
  exit 1
fi
