# Classic Zsh Tab Completion + Carapace Specs

# 1. Carapace — universal command/flag completion engine
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  source <(carapace _carapace)

  # Restore native zsh git completion (carapace git completion has issues with `git add`)
  compdef _git git
fi

# 2. Classic Zsh Completion Options & Menu Select Grid
zstyle ':completion:*' menu select
setopt ALWAYS_LAST_PROMPT AUTO_MENU COMPLETE_IN_WORD
unsetopt LIST_BEEP

# Completion styles & matching rules
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*:descriptions' format '%F{yellow}%B── %d ──%b%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Navigation inside menu select
bindkey "$terminfo[kcbt]" reverse-menu-complete 2>/dev/null
bindkey -M menuselect '^[' send-break
bindkey -M menuselect '^M' .accept-line
bindkey -M menuselect '^J' .accept-line

# Classic history search fallback
bindkey '^R' history-incremental-search-backward

# History substring search (up/down arrow & ctrl-p/ctrl-n)
if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi