# Completion stack: carapace specs + fzf-tab UI.
# Requires: carapace (brew), fzf-tab (antidote), fzf.

# Carapace — universal command/flag completion specs.
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  zstyle ':completion:*' format $'\e[2;37m%d\e[m'
  source <(carapace _carapace)
fi

# Canonical tab completion
zstyle ':completion:*' menu select
setopt ALWAYS_LAST_PROMPT AUTO_MENU COMPLETE_IN_WORD
unsetopt LIST_BEEP

_zsh_tab_complete() {
  if [[ -n ${POSTDISPLAY:-} && ${+widgets[autosuggest-accept]} -eq 1 ]]; then
    zle autosuggest-accept
    return
  fi
  zle menu-complete
}
zle -N _zsh_tab_complete
bindkey '^I' _zsh_tab_complete
bindkey "$terminfo[kcbt]" reverse-menu-complete 2>/dev/null
bindkey -M menuselect '^[' send-break
bindkey -M menuselect '^M' .accept-line
bindkey -M menuselect '^J' .accept-line

# Classic history search
bindkey '^R' history-incremental-search-backward

# History substring search (up/down with prefix).
if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi