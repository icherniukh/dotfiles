# Plugin and completion setup (zgenom + Homebrew extras)

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

# Lazy-load nvm (only load when node/npm/nvm is actually used)
# This saves ~330ms on shell startup
export NVM_LAZY_LOAD=true
# Optional: add extra commands to trigger nvm loading
export NVM_LAZY_LOAD_EXTRA_COMMANDS="node npm npx"

source "${HOME}/.zgenom/zgenom.zsh"

zgenom autoupdate

if ! zgenom saved; then
    echo "Creating a zgenom save"
    zgenom compdef

    zgenom load zpm-zsh/colors
    zgenom load zdharma-continuum/colorize
    zgenom load https://gitlab.com/code-stats/code-stats-zsh.git
    zgenom load lukechilds/zsh-nvm
    zgenom load lukechilds/zsh-better-npm-completion
    zgenom load supercrabtree/k
    # 2026-03-21: Disabled zsh-completion-generator for performance
    # - Was taking ~317ms (38% of shell startup time)
    # - Testing built-in zsh completions instead
    # - RE-ENABLE if completions are broken or missing for commands you use
    # zgenom load RobSis/zsh-completion-generator
    zgenom load unixorn/fzf-zsh-plugin
    zgenom load unixorn/git-extra-commands
    zgenom load zpm-zsh/clipboard
    zgenom load zdharma-continuum/history-search-multi-word
    zgenom load akash329d/zsh-alias-finder
    zgenom load gretzky/auto-color-ls
    zgenom load mfaerevaag/wd

    zgenom bin tj/git-extras
    zgenom save
    zgenom compile "$HOME/.zshrc"
fi

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

command -v thefuck >/dev/null 2>&1 && eval $(thefuck --alias)

[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
