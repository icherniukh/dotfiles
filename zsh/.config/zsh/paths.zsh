# Path and tool location setup
export PATH="$HOME/.scripts:$PATH"

# MacPorts
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Homebrew Ruby - main binaries
export PATH="${BREW_PREFIX}/opt/ruby/bin:$PATH"

# Homebrew Ruby gems - use highest version number dynamically
# Sorts numerically so 4.0.0 > 3.4.0, handles both 3.x and 4.x maintenance
_ruby_gem_versions=(${BREW_PREFIX}/lib/ruby/gems/*/bin(N))
if [[ $#_ruby_gem_versions -gt 0 ]]; then
  # Sort numerically and take the highest version
  _ruby_highest_version=$(printf '%s\n' "${_ruby_gem_versions[@]}" | sort -V | tail -1)
  export PATH="${_ruby_highest_version}:$PATH"
fi
unset _ruby_gem_versions _ruby_highest_version

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Workspace shortcuts
export PATH="$PATH:$HOME/.claude/agents:$HOME/.claude/context:$HOME/.claude/templates"

# Kiro/Windsurf/other CLI additions
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# OpenCode
export PATH="$HOME/.opencode/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

typeset -U path PATH
