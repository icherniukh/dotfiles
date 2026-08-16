# Path and tool location setup. Keep PATH and zsh's path array synchronized and
# de-duplicated, and never add optional directories that do not exist.
typeset -U path PATH

# Remove entries this config has historically managed before rebuilding them.
# This also repairs shells launched from a parent that still exports the old PATH.
_managed_path_dirs=(
  "$HOME/.scripts"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/bin"
  "$HOME/venvs/transcribe/bin"
  "$HOME/.nix-profile/bin"
  "$HOME/.claude/agents"
  "$HOME/.claude/context"
  "$HOME/.claude/templates"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.opencode/bin"
  "$HOME/.bun/bin"
)
for _managed_path_dir in "${_managed_path_dirs[@]}"; do
  path=(${path:#$_managed_path_dir})
done
unset _managed_path_dir _managed_path_dirs

[[ -d "$HOME/.scripts" ]] && path=("$HOME/.scripts" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)
[[ -d /snap/bin ]] && path=(/snap/bin $path)

# Nix is installed system-wide on macOS, but non-login shells do not always
# source /etc/profile.d automatically.
[[ -f /etc/profile.d/nix.sh ]] && source /etc/profile.d/nix.sh
# The multi-user Nix init unconditionally adds the legacy per-user profile,
# even on machines where that profile has never been created.
[[ -d "$HOME/.nix-profile/bin" ]] || path=(${path:#$HOME/.nix-profile/bin})

# Package manager core bins
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:$PATH"

# MacPorts (macOS only)
[[ "$(uname)" == "Darwin" && -d /opt/local/bin ]] && export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Homebrew Ruby - main binaries
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/opt/ruby/bin:$PATH"

# Ruby gem executables - include the active Ruby's bindir and per-user gem bin.
# This covers user-installed gems like `colorls`, not just Homebrew-managed gems.
if command -v ruby >/dev/null 2>&1; then
  _ruby_runtime_paths=(${(f)"$(ruby -rrubygems -e 'puts Gem.bindir; puts File.join(Gem.user_dir, %q{bin})' 2>/dev/null)"})
  for _ruby_path in "${_ruby_runtime_paths[@]}"; do
    [[ -n "$_ruby_path" && -d "$_ruby_path" ]] && export PATH="$_ruby_path:$PATH"
  done
  unset _ruby_path _ruby_runtime_paths
fi

# Homebrew Ruby gems - use highest version number dynamically
# Sorts numerically so 4.0.0 > 3.4.0, handles both 3.x and 4.x maintenance
_ruby_gem_versions=(${BREW_PREFIX:+${BREW_PREFIX}/lib/ruby/gems/*/bin}(N))
if [[ $#_ruby_gem_versions -gt 0 ]]; then
  # Sort numerically and take the highest version
  _ruby_highest_version=$(printf '%s\n' "${_ruby_gem_versions[@]}" | sort -V | tail -1)
  export PATH="${_ruby_highest_version}:$PATH"
fi
unset _ruby_gem_versions _ruby_highest_version

# `pyenv init -` adds shims, completion, and rehash hooks; PATH alone is not enough.
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Kiro/Windsurf/other CLI additions
[[ -d "$HOME/.codeium/windsurf/bin" ]] && path+=("$HOME/.codeium/windsurf/bin")
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path+=("$HOME/.antigravity/antigravity/bin")

# OpenCode
[[ -d "$HOME/.opencode/bin" ]] && path+=("$HOME/.opencode/bin")

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && path+=("$BUN_INSTALL/bin")
