# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

if [[ "$ZPROF" = true ]]; then
  echo "  ## Running ZPROF on .zshrc"
  zmodload zsh/zprof
fi

# Secrets and core config
[[ -f "${ZSH_CONFIG_DIR}/secrets.zsh" ]] && source "${ZSH_CONFIG_DIR}/secrets.zsh"
[[ -f "${ZSH_CONFIG_DIR}/env.zsh" ]] && source "${ZSH_CONFIG_DIR}/env.zsh"
[[ -f "${ZSH_CONFIG_DIR}/paths.zsh" ]] && source "${ZSH_CONFIG_DIR}/paths.zsh"
[[ -f "${ZSH_CONFIG_DIR}/options.zsh" ]] && source "${ZSH_CONFIG_DIR}/options.zsh"

# Plugins/prompt
[[ -f "${ZSH_CONFIG_DIR}/plugins.zsh" ]] && source "${ZSH_CONFIG_DIR}/plugins.zsh"
[[ -f "${ZSH_CONFIG_DIR}/prompt.zsh" ]] && source "${ZSH_CONFIG_DIR}/prompt.zsh"

# Local customizations
[[ -f "${ZSH_CONFIG_DIR}/aliases.zsh" ]] && source "${ZSH_CONFIG_DIR}/aliases.zsh"
[[ -f "${ZSH_CONFIG_DIR}/functions.zsh" ]] && source "${ZSH_CONFIG_DIR}/functions.zsh"
[[ -f "${ZSH_CONFIG_DIR}/zshrc_prof.zsh" ]] && source "${ZSH_CONFIG_DIR}/zshrc_prof.zsh"
[[ -f "${ZSH_CONFIG_DIR}/apikeys.zsh" ]] && source "${ZSH_CONFIG_DIR}/apikeys.zsh"
[[ -f "${ZSH_CONFIG_DIR}/ccconfig.zsh" ]] && source "${ZSH_CONFIG_DIR}/ccconfig.zsh"
# Optional: sync `~/.scripts` → `~/.local/bin` on every shell start (disabled by default).
# [[ -x "${ZSH_CONFIG_DIR}/sync-scripts.zsh" ]] && "${ZSH_CONFIG_DIR}/sync-scripts.zsh"

# Host-local overrides (git-ignored)
[[ -f "${ZSH_CONFIG_DIR}/local.zsh" ]] && source "${ZSH_CONFIG_DIR}/local.zsh"


[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

if [[ "$ZPROF" = true ]]; then
  echo "  ## Finished ZPROF"
  zprof
fi

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"
