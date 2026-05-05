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

# Drop Ghostty-generated wrappers before sourcing `local.zsh` so `source ~/.zshrc`
# does not run generated completions through an already wrapped command function.
for _gat_tool in codex claude aider goose gemini; do
  if [[ ${functions_source[$_gat_tool]-} == */ghostty-ai-themes.zsh ]]; then
    unfunction "$_gat_tool"
  fi
done
unset _gat_tool

# Host-local shell hooks and generated completions live in `local.zsh`; load them before terminal wrappers.
[[ -f "${ZSH_CONFIG_DIR}/local.zsh" ]] && source "${ZSH_CONFIG_DIR}/local.zsh"

# Ghostty AI themes wrap selected AI CLIs with per-command colors and reset the palette afterward.
_gat_script="${BREW_PREFIX:+${BREW_PREFIX}/share/ghostty-ai-themes.zsh}"
[[ -n "${_gat_script:-}" && -f "$_gat_script" ]] && source "$_gat_script"
unset _gat_script

# Autojump (try Homebrew, then system paths)
if [[ -n "${BREW_PREFIX:-}" && -f "${BREW_PREFIX}/etc/profile.d/autojump.sh" ]]; then
  source "${BREW_PREFIX}/etc/profile.d/autojump.sh"
elif [[ -f /usr/share/autojump/autojump.zsh ]]; then
  source /usr/share/autojump/autojump.zsh
elif [[ -f /usr/share/autojump/autojump.sh ]]; then
  source /usr/share/autojump/autojump.sh
fi

# Bun completions
[[ -f "${HOME}/.bun/_bun" ]] && source "${HOME}/.bun/_bun"
# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{yellow}%B── %d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' list-separator '  '
zstyle ':completion:*' group-name ''

# Eval shell init only when the generator succeeds and writes code to stdout.
_eval_init() {
  local init_script
  init_script="$("$@" 2>/dev/null)" || return 0
  [[ -n "$init_script" ]] || return 0
  eval "$init_script"
}

# Load tv's own shell init first; the custom dispatcher below only changes completion candidates.
_eval_init tv init zsh
# Override upstream `_tv` to group flags and add dynamic channels from `tv list-channels`.
_tv_complete() {
  case $words[2] in
    -*)
      compadd -- --ansi --autocomplete-prompt --cable-dir --cache-preview \
        --config-file --exact --expect --global-history --height --help \
        --hide-help-panel --hide-preview --hide-preview-scrollbar --hide-remote \
        --hide-status-bar --inline --input --input-border --input-header \
        --input-padding --input-position --input-prompt --keybindings --layout \
        --no-help-panel --no-preview --no-remote --no-sort --no-status-bar \
        --preview-border --preview-command --preview-footer --preview-header \
        --preview-offset --preview-padding --preview-size --preview-word-wrap \
        --results-border --results-padding --select-1 --show-help-panel \
        --show-preview --show-remote --show-status-bar --source-command \
        --source-display --source-entry-delimiter --source-output --take-1 \
        --take-1-fast --tick-rate --ui-scale --version --watch --width \
        -h -V -s -p -i -t -k
      ;;
    *)
      local -a cmd_names cmd_display channels
      cmd_names=(list-channels init completions update-channels)
      cmd_display=(
        $'\e[1mlist-channels\e[0m    \e[2m-- list available channels\e[0m'
        $'\e[1minit\e[0m             \e[2m-- initialize shell integration\e[0m'
        $'\e[1mcompletions\e[0m      \e[2m-- generate tab-completion script\e[0m'
        $'\e[1mupdate-channels\e[0m  \e[2m-- download latest channel prototypes\e[0m'
      )
      channels=(${(f)"$(tv list-channels 2>/dev/null)"})
      compadd -V commands -X '%F{yellow}%B── commands%b%f' -l -d cmd_display -- $cmd_names
      compadd -V channels -X '%F{yellow}%B── channels%b%f' -a channels
      ;;
  esac
}
compdef _tv_complete tv
unset -f _eval_init
export CLAUDE_CODE_NO_FLICKER=1
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/venvs/transcribe/bin:$PATH"

if [[ "$ZPROF" = true ]]; then
  echo "  ## Finished ZPROF"
  zprof
fi
