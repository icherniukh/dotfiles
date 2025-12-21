# Path and tool location setup
export PATH="$HOME/.scripts:$PATH"
export PATH="${BREW_PREFIX}/opt/ruby/bin:${BREW_PREFIX}/lib/ruby/gems/3.4.0/bin:$PATH"

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

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

typeset -U path PATH
