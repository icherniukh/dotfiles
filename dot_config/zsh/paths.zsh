# Path and tool location setup
export PATH="$HOME/.local/bin:$HOME/.scripts:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Package manager core bins
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:$PATH"

# MacPorts (macOS only)
[[ "$(uname)" == "Darwin" && -d /opt/local/bin ]] && export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Homebrew Ruby - main binaries
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/opt/ruby/bin:$PATH"

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

# Workspace shortcuts
export PATH="$PATH:$HOME/.claude/agents:$HOME/.claude/context:$HOME/.claude/templates"

# Kiro/Windsurf/other CLI additions
export PATH="$PATH:$HOME/.codeium/windsurf/bin"
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

# OpenCode
export PATH="$PATH:$HOME/.opencode/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$PATH:$BUN_INSTALL/bin"

typeset -U path PATH
