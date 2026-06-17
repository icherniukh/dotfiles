# Machine-local tweaks go here. Copy to local.zsh to activate.
# Use this for host-only shell integrations or generated completions you do not want in git.
# Tab completion (carapace + fzf-tab) lives in completion.zsh — do not duplicate here.

# Ghostty shell integration
if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi

# Generated CLI completions (use the real binary, not Ghostty-wrapped shell functions)
# codex_bin="$(whence -p codex 2>/dev/null)"
# [[ -n "$codex_bin" ]] && eval "$("$codex_bin" completion zsh)"
# unset codex_bin