# Plugin and completion setup (antidote + Homebrew extras)

# Completions (run early so compdef exists for plugins)
_zsh_completion_refresh=0
_zsh_generated_completions="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/site-functions"
if mkdir -p "$_zsh_generated_completions" >/dev/null 2>&1 && command -v bd >/dev/null 2>&1; then
  _bd_completion="${_zsh_generated_completions}/_bd"
  _bd_bin="$(command -v bd)"
  if [[ ! -f "$_bd_completion" || "$_bd_bin" -nt "$_bd_completion" ]]; then
    if bd completion zsh >| "$_bd_completion" 2>/dev/null; then
      _zsh_completion_refresh=1
    else
      rm -f "$_bd_completion"
    fi
  fi
  unset _bd_bin _bd_completion
fi
if type brew &>/dev/null; then
  FPATH="${BREW_PREFIX}/share/zsh-completions:$FPATH"
fi
fpath=("$HOME/.local/share/zsh/site-functions" "$_zsh_generated_completions" $fpath)
unset _zsh_generated_completions
autoload -Uz compinit
zmodload zsh/complist
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
if [[ $_zsh_completion_refresh -eq 1 ]]; then
  compinit -d "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi
unset _zsh_completion_refresh

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
zsh_plugins="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/plugins.zsh"
zsh_plugins_dir="${zsh_plugins:h}"
if mkdir -p "$zsh_plugins_dir" >/dev/null 2>&1 && [[ ! -f $zsh_plugins || ~/.zsh_plugins.txt -nt $zsh_plugins ]]; then
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
unset zsh_plugins_dir
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
