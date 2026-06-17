# Completion stack: carapace specs + fzf-tab UI.
# Requires: carapace (brew), fzf-tab (antidote), fzf.

# Carapace — universal command/flag completion specs.
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  zstyle ':completion:*' format $'\e[2;37m%d\e[m'
  source <(carapace _carapace)
fi

# fzf-tab — fzf popup for completion selection.
if (( ${+widgets[fzf-tab-complete]} )); then
  _zsh_fzf_tab_complete() {
    (( ${+widgets[autosuggest-clear]} )) && zle autosuggest-clear
    POSTDISPLAY=
    zle fzf-tab-complete
  }
  zle -N _zsh_fzf_tab_complete
  bindkey '^I' _zsh_fzf_tab_complete
  bindkey "$terminfo[kcbt]" fzf-tab-complete 2>/dev/null

  zstyle ':completion:*' menu no
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':fzf-tab:*' continuous-trigger '/'
  zstyle ':fzf-tab:*' fzf-flags \
    --height=40% --layout=reverse --border=rounded \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  zstyle ':fzf-tab:complete:*:*' fzf-preview \
    'if [ -d $realpath ]; then eza -1 --color=always $realpath 2>/dev/null || ls -1 $realpath; else bat --style=numbers --color=always --line-range :200 $realpath 2>/dev/null; fi'
  zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview 'brew info $word 2>/dev/null | head -40'
fi

# History substring search (up/down with prefix).
if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi