# Plugin and completion setup (antidote + Homebrew extras)

# Completions (run early so compdef exists for plugins)
if type brew &>/dev/null; then
  FPATH="${BREW_PREFIX}/share/zsh-completions:$FPATH"
fi
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
autoload -Uz compinit
zmodload zsh/complist
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
compinit -C -d "$ZSH_COMPDUMP"

zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# `fnm env --use-on-cd` installs the on-directory-change Node version hooks.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Generate a static plugin bundle from `.zsh_plugins.txt` instead of resolving plugins on every shell start.
zsh_plugins=~/.zsh_plugins.zsh
if [[ ! -f $zsh_plugins || ~/.zsh_plugins.txt -nt $zsh_plugins ]]; then
  # Locate antidote: Homebrew (macOS/Linux) or system install
  _antidote_path=""
  if [[ -f "${BREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh" ]]; then
    _antidote_path="${BREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh"
  elif [[ -f "${HOME}/.antidote/antidote.zsh" ]]; then
    _antidote_path="${HOME}/.antidote/antidote.zsh"
  fi
  if [[ -n "$_antidote_path" ]]; then
    source "$_antidote_path"
    antidote bundle <~/.zsh_plugins.txt >$zsh_plugins
  fi
  unset _antidote_path
fi
# Only load widget-heavy plugins when zle has a real terminal to attach to.
if [[ -t 0 && -t 1 ]]; then
  [[ -f $zsh_plugins ]] && source $zsh_plugins

  # Plugin configs (Homebrew-installed using BREW_PREFIX for portability)
  [[ -f "${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "${BREW_PREFIX}/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] && \
    source "${BREW_PREFIX}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"

  typeset -gA HSMW_HIGHLIGHT_STYLES
  HSMW_HIGHLIGHT_STYLES[path]="bg=magenta,fg=white,bold"
  HSMW_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
  HSMW_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"

  zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"
  zstyle ":history-search-multi-word" page-size "8"
  zstyle ":plugin:history-search-multi-word" active "underline"
  zstyle ":plugin:history-search-multi-word" check-paths "yes"
  zstyle ":plugin:history-search-multi-word" clear-on-cancel "no"
  zstyle ":plugin:history-search-multi-word" synhl "yes"

  # fzf (config tracked under `${XDG_CONFIG_HOME:-$HOME/.config}/fzf`)
  if command -v fzf >/dev/null 2>&1; then
    [[ -n ${FZF_PATH-} && -f "${FZF_PATH}/fzf.zsh" ]] && source "${FZF_PATH}/fzf.zsh"
  fi

  [[ -f ${BREW_PREFIX}/share/forgit/forgit.plugin.zsh ]] && \
    source ${BREW_PREFIX}/share/forgit/forgit.plugin.zsh
fi

command -v thefuck >/dev/null 2>&1 && thefuck() { unfunction thefuck; eval $(command thefuck --alias); thefuck "$@"; }

[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"
