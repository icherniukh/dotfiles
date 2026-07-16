# Path and tool location setup
export PATH="$HOME/.local/bin:$HOME/.scripts:$PATH"

# Nix is installed system-wide on macOS, but non-login shells do not always
# source /etc/profile.d automatically.
[[ -f /etc/profile.d/nix.sh ]] && source /etc/profile.d/nix.sh

# Package manager core bins
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:$PATH"

# OS-specific paths
local os_paths="${ZSH_CONFIG_DIR}/paths.$(uname | tr '[:upper:]' '[:lower:]').zsh"
[[ -f "$os_paths" ]] && source "$os_paths"

# mise activation
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# mise's Rust backend delegates to rustup, so rustc/cargo are rustup shims.
[[ -n "${CARGO_HOME:-}" && -d "$CARGO_HOME/bin" ]] && export PATH="$CARGO_HOME/bin:$PATH"

# Workspace shortcuts
export PATH="$PATH:$HOME/.claude/agents:$HOME/.claude/context:$HOME/.claude/templates"

# Kiro/Windsurf/other CLI additions
export PATH="$PATH:$HOME/.codeium/windsurf/bin"
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

# OpenCode
export PATH="$PATH:$HOME/.opencode/bin"

typeset -U path PATH
