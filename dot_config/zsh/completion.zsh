# Classic Zsh Tab Completion + Carapace Specs

# 1. Carapace — universal command/flag completion engine
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  source <(carapace _carapace)

  # Restore native zsh git completion (carapace git completion has issues with `git add`)
  compdef _git git
fi

# Prefer the installed tools' own specifications over Carapace's bundled ones.
for _completion_tool in codex hunk mise uv; do
  _completion_bin="$(whence -p "$_completion_tool")" || continue
  if [[ $_completion_tool == uv ]]; then
    _completion_script="$("$_completion_bin" generate-shell-completion zsh 2>/dev/null)" || continue
  else
    _completion_script="$("$_completion_bin" completion zsh 2>/dev/null)" || continue
  fi
  [[ -n $_completion_script ]] && eval "$_completion_script"
done
unset _completion_tool _completion_bin _completion_script

# These CLIs have no installed zsh generator. Zsh reads their current --help
# for flags and still offers files for positional arguments.
compdef _gnu_generic claude composio

# 2. Classic Zsh Completion Options & Menu Select Grid
# Long option lists must scroll inside the menu rather than spill into scrollback.
zstyle ':completion:*' menu yes select
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
# A standalone Escape dismisses the list without executing the command.
# Keep escape-prefixed arrow/Alt bindings intact.
_dismiss_completion() {
  (( ${+widgets[autosuggest-clear]} )) && zle autosuggest-clear
  zle -R -c
}
zle -N _dismiss_completion
# Note: intentionally NOT binding '^[' in the emacs map — bare ESC races with
# arrow key escape sequences (^[[D etc.) and intermittently swallows them.
# The menuselect binding is safe: it only fires when the completion menu is open.
bindkey -M menuselect '^[' _dismiss_completion
bindkey -M menuselect '^M' .accept-line
bindkey -M menuselect '^J' .accept-line

# Keep native Ctrl-R history search after integrations (tv also binds Ctrl-R).
_bind_history_search() {
  bindkey '^R' history-incremental-search-backward
}
_bind_history_search
autoload -Uz add-zsh-hook
add-zsh-hook precmd _bind_history_search

# History substring search and autosuggestion bindings must run after plugins
# are fully loaded. Guards at source time fail because antidote loads plugins
# after completion.zsh. A self-removing precmd hook fires on the first prompt,
# by which point all ZLE widgets are registered.
_late_bindings_done=0
_late_key_bindings() {
  (( _late_bindings_done )) && return
  _late_bindings_done=1

  # Up/down arrows: substring search if available, fall back to plain history
  if (( ${+widgets[history-substring-search-up]} )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P'   history-substring-search-up
    bindkey '^N'   history-substring-search-down
  fi

  # ^F and ^E explicitly accept the full autosuggestion.
  # Right arrow (^[[C) is intentionally left at its default forward-char binding:
  # at EOL it accepts the suggestion; mid-line it just moves the cursor right.
  if (( ${+widgets[autosuggest-accept]} )); then
    bindkey '^F'   autosuggest-accept
    bindkey '^E'   autosuggest-accept
  fi
}
add-zsh-hook precmd _late_key_bindings
