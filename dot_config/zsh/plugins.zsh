# Plugin and completion setup (antidote + carapace + generated completions)

# 1. Build fpath before plugins and compinit.
_zsh_completion_refresh=0
_zsh_generated_completions="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/site-functions"
# Generate bd completion from the installed binary; regenerate when bd is upgraded.
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
  FPATH="${BREW_PREFIX}/share/zsh/site-functions:${BREW_PREFIX}/share/zsh-completions:$FPATH"
fi
fpath=("$ZSH_CONFIG_DIR/site-functions" "$HOME/.local/share/zsh/site-functions" "$_zsh_generated_completions" $fpath)
typeset -U fpath  # deduplicate — brew shellenv + login shell can double-add paths
unset _zsh_generated_completions
zmodload zsh/complist

# 2. Generate a static plugin bundle from `.zsh_plugins.txt` instead of resolving plugins on every shell start.
_zsh_plugins_src="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
zsh_plugins="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/plugins.zsh"
if mkdir -p "${zsh_plugins:h}" >/dev/null 2>&1 && [[ ! -f $zsh_plugins || "$_zsh_plugins_src" -nt $zsh_plugins ]]; then
  # Locate antidote: Homebrew (macOS/Linux) or system install
  _antidote_path=""
  if [[ -f "${BREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh" ]]; then
    _antidote_path="${BREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh"
  elif [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
    _antidote_path="${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
  fi
  if [[ -n "$_antidote_path" ]]; then
    source "$_antidote_path"
    antidote bundle <"$_zsh_plugins_src" >|$zsh_plugins
  fi
  unset _antidote_path
fi
unset _zsh_plugins_src

# 3. Load plugins first — some (forgit, wd, zsh-completions) add completions to fpath.
#    Widget-heavy plugins need zle, so only load them when a real terminal is attached.
#    Plugins that call compdef at load time (e.g. zsh-better-npm-completion) get a
#    queue until compinit defines the real one.
typeset -ga _zsh_deferred_compdefs
if [[ -t 0 && -t 1 ]]; then
  (( ${+functions[compdef]} )) || compdef() { _zsh_deferred_compdefs+=("${(pj:\0:)@}"); }
  [[ -f $zsh_plugins ]] && source $zsh_plugins

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

  # fzf (config tracked under `${XDG_CONFIG_HOME:-$HOME/.config}/fzf`).
  # unixorn/fzf-zsh-plugin already sources "$FZF_PATH/fzf.zsh"; only do it here without the plugin.
  if command -v fzf >/dev/null 2>&1 && (( ! ${+aliases[fkill]} )); then
    [[ -n ${FZF_PATH-} && -f "${FZF_PATH}/fzf.zsh" ]] && source "${FZF_PATH}/fzf.zsh"
  fi
fi

# 4. Run compinit AFTER plugins so all fpath additions are visible, in every
#    interactive shell. Rebuild the dump when it is missing, older than a day,
#    or a generated completion changed; otherwise load it without the audit (-C).
if [[ -o interactive ]]; then
  (( ${#_zsh_deferred_compdefs} )) && unfunction compdef 2>/dev/null
  autoload -Uz compinit
  ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
  _zsh_stale_dump=("$ZSH_COMPDUMP"(N.mh+24))
  if (( _zsh_completion_refresh || $#_zsh_stale_dump )) || [[ ! -s "$ZSH_COMPDUMP" ]]; then
    compinit -d "$ZSH_COMPDUMP"
    { zcompile "$ZSH_COMPDUMP" } &!
  else
    compinit -C -d "$ZSH_COMPDUMP"
  fi
  unset ZSH_COMPDUMP _zsh_stale_dump

  for _zsh_compdef_args in "${_zsh_deferred_compdefs[@]}"; do
    compdef "${(@ps:\0:)_zsh_compdef_args}"
  done
  unset _zsh_compdef_args

  [[ -f "${ZSH_CONFIG_DIR}/completion.zsh" ]] && source "${ZSH_CONFIG_DIR}/completion.zsh"
fi
unset _zsh_completion_refresh _zsh_deferred_compdefs

command -v thefuck >/dev/null 2>&1 && fuck() { unfunction fuck; eval "$(command thefuck --alias fuck)"; fuck "$@"; }

[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi
