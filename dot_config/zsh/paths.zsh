# Path and tool location setup. Keep PATH and zsh's path array synchronized and
# de-duplicated, and never add optional directories that do not exist.
typeset -U path PATH

# Remove entries this config has historically managed before rebuilding them.
# This also repairs shells launched from a parent that still exports the old PATH.
_managed_path_dirs=(
  "$HOME/.scripts"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/bin"
  "$HOME/venvs/transcribe/bin"
  "$HOME/.nix-profile/bin"
  "$HOME/.claude/agents"
  "$HOME/.claude/context"
  "$HOME/.claude/templates"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.opencode/bin"
  "$HOME/.bun/bin"
)
for _managed_path_dir in "${_managed_path_dirs[@]}"; do
  path=(${path:#$_managed_path_dir})
done
unset _managed_path_dir _managed_path_dirs

[[ -d "$HOME/.scripts" ]] && path=("$HOME/.scripts" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)
[[ -d /snap/bin ]] && path=(/snap/bin $path)

# Nix is installed system-wide on macOS, but non-login shells do not always
# source /etc/profile.d automatically.
[[ -f /etc/profile.d/nix.sh ]] && source /etc/profile.d/nix.sh
# The multi-user Nix init unconditionally adds the legacy per-user profile,
# even on machines where that profile has never been created.
[[ -d "$HOME/.nix-profile/bin" ]] || path=(${path:#$HOME/.nix-profile/bin})

# Package manager core bins
[[ -n "${BREW_PREFIX:-}" ]] && export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:$PATH"

# OS-specific paths
_os_paths="${ZSH_CONFIG_DIR}/paths.${(L)$(uname)}.zsh"
[[ -f "$_os_paths" ]] && source "$_os_paths"
unset _os_paths

# Language runtimes: mise owns node/python/ruby/bun/rust where it is installed
# (see docs/runtime-transition.html). Machines without mise keep the legacy
# per-tool setup below.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
  # mise's Rust backend delegates to rustup, so rustc/cargo are rustup shims.
  [[ -n "${CARGO_HOME:-}" && -d "$CARGO_HOME/bin" ]] && export PATH="$CARGO_HOME/bin:$PATH"
else
  # Homebrew Ruby - main binaries
  [[ -n "${BREW_PREFIX:-}" && -d "${BREW_PREFIX}/opt/ruby/bin" ]] && export PATH="${BREW_PREFIX}/opt/ruby/bin:$PATH"

  # Ruby gem executables - include the active Ruby's bindir and per-user gem bin.
  # This covers user-installed gems like `colorls`, not just Homebrew-managed gems.
  if command -v ruby >/dev/null 2>&1; then
    _ruby_runtime_paths=(${(f)"$(ruby -rrubygems -e 'puts Gem.bindir; puts File.join(Gem.user_dir, %q{bin})' 2>/dev/null)"})
    for _ruby_path in "${_ruby_runtime_paths[@]}"; do
      [[ -n "$_ruby_path" && -d "$_ruby_path" ]] && export PATH="$_ruby_path:$PATH"
    done
    unset _ruby_path _ruby_runtime_paths
  fi

  # `pyenv init -` adds shims, completion, and rehash hooks; PATH alone is not enough.
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

  # `fnm env --use-on-cd` installs the on-directory-change Node version hooks.
  command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell zsh)"

  # Bun
  export BUN_INSTALL="$HOME/.bun"
  [[ -d "$BUN_INSTALL/bin" ]] && path+=("$BUN_INSTALL/bin")
fi

# Kiro/Windsurf/other CLI additions
[[ -d "$HOME/.codeium/windsurf/bin" ]] && path+=("$HOME/.codeium/windsurf/bin")
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path+=("$HOME/.antigravity/antigravity/bin")

# OpenCode
[[ -d "$HOME/.opencode/bin" ]] && path+=("$HOME/.opencode/bin")

# Move user bins back to the front, ahead of Homebrew/MacPorts and runtime
# managers, so local wrappers and self-installed tools (incl. mise) win.
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)
