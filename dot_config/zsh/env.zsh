# Common environment configuration (non-secret).
export EDITOR=hx
export VISUAL=hx

# Detect Homebrew prefix (macOS: /opt/homebrew, Linux: /home/linuxbrew/.linuxbrew)
if [[ -z "${BREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then       # Apple Silicon macOS
    BREW_PREFIX=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then         # Intel macOS
    BREW_PREFIX=/usr/local
  elif [[ -d /home/linuxbrew/.linuxbrew ]]; then  # Linux Homebrew
    BREW_PREFIX=/home/linuxbrew/.linuxbrew
  elif command -v brew >/dev/null 2>&1; then       # fallback
    BREW_PREFIX="$(brew --prefix)"
  fi
fi
export BREW_PREFIX
export HOMEBREW_NO_ENV_HINTS=1
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# XDG paths
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

# Zsh cache/history locations (HISTFILE set in ~/.zshenv for early read)
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
mkdir -p "$ZSH_CACHE_DIR" "$(dirname "${HISTFILE:-$XDG_STATE_HOME/zsh/history}")" >/dev/null 2>&1

# Re-assert after /etc/zshrc (macOS defaults HISTSIZE=2000, HISTFILE=~/.zsh_history).
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=6969420
SAVEHIST=6969420

# Color/theme defaults
# Cache LS_COLORS — only regenerate if vivid binary is newer than cache
_vivid_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/ls_colors"
if [[ ! -f "$_vivid_cache" || "$(command -v vivid)" -nt "$_vivid_cache" ]]; then
  vivid generate one-dark >| "$_vivid_cache" 2>/dev/null
fi
[[ -f "$_vivid_cache" ]] && export LS_COLORS=$(<"$_vivid_cache")
unset _vivid_cache

# Misc tool defaults (portability improved)
[[ -n "${BREW_PREFIX:-}" ]] && export GSETTINGS_SCHEMA_DIR="${BREW_PREFIX}/share/glib-2.0/schemas"
export STARSHIP_CACHE=${STARSHIP_CACHE:-$HOME/.starship/cache}
export FZF_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/fzf"
