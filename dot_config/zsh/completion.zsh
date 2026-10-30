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
# Note: intentionally NOT binding '^[' in the emacs map — bare ESC races with
# arrow key escape sequences (^[[D etc.) and intermittently swallows them.
# Native send-break leaves menu selection and restores the original input.
bindkey -M menuselect '^[' send-break
bindkey -M menuselect '^M' .accept-line
bindkey -M menuselect '^J' .accept-line

# Ctrl-R opens history-search-multi-word's match list below the prompt; reassert it after
# integrations that steal the key (tv). Native search is the fallback without the plugin.
_bind_history_search() {
  if (( ${+widgets[history-search-multi-word]} )); then
    bindkey '^R' history-search-multi-word
  else
    bindkey '^R' history-incremental-search-backward
  fi
}
_bind_history_search
autoload -Uz add-zsh-hook
add-zsh-hook precmd _bind_history_search

_up_line_or_local_history() {
  zle set-local-history -n 1
  zle up-line-or-history
  zle set-local-history -n 0
}
_down_line_or_local_history() {
  zle set-local-history -n 1
  zle down-line-or-history
  zle set-local-history -n 0
}
zle -N _up_line_or_local_history
zle -N _down_line_or_local_history

# History substring search and autosuggestion bindings must run after plugins
# are fully loaded. Guards at source time fail because antidote loads plugins
# after completion.zsh. A self-removing precmd hook fires on the first prompt,
# by which point all ZLE widgets are registered.
_late_bindings_done=0
_late_key_bindings() {
  (( _late_bindings_done )) && return
  _late_bindings_done=1

  # Up/Down and ^P/^N cycle this shell's own commands without filtering on the typed text;
  # commands SHARE_HISTORY imports from other tabs are skipped (Ctrl-R searches everything).
  local key
  for key in '^[[A' '^[OA' '^P'; do bindkey "$key" _up_line_or_local_history; done
  for key in '^[[B' '^[OB' '^N'; do bindkey "$key" _down_line_or_local_history; done

  # ^F and ^E explicitly accept the full autosuggestion.
  # Right arrow (^[[C) is intentionally left at its default forward-char binding:
  # at EOL it accepts the suggestion; mid-line it just moves the cursor right.
  if (( ${+widgets[autosuggest-accept]} )); then
    bindkey '^F'   autosuggest-accept
    bindkey '^E'   autosuggest-accept
  fi
}
add-zsh-hook precmd _late_key_bindings
