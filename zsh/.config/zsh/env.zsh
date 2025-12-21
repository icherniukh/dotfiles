# Common environment configuration (non-secret).
export EDITOR=hx
export BREW_PREFIX=${BREW_PREFIX:-$(/opt/homebrew/bin/brew --prefix 2>/dev/null)}
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# XDG paths
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

# Zsh cache/history locations
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
mkdir -p "$ZSH_CACHE_DIR" "$(dirname "$HISTFILE")" >/dev/null 2>&1

# Color/theme defaults
export LS_COLORS=$(vivid generate one-dark)

# History settings
export HISTORY_SECRET=<REDACTED>
HISTSIZE=6969420
SAVEHIST=6969420

# Misc tool defaults (portability improved)
export GSETTINGS_SCHEMA_DIR="${BREW_PREFIX}/share/glib-2.0/schemas"
export STARSHIP_CACHE=${STARSHIP_CACHE:-$HOME/.starship/cache}
export FZF_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/fzf"
