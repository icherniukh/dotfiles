# Common environment configuration (non-secret).
export EDITOR=hx

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

# On Linux, /tmp is commonly a RAM-backed tmpfs sized to a fraction of total
# memory (systemd default). That's fine for small scratch files, but build
# tools (cargo, npm, pip) can dump multi-GB artifacts into $TMPDIR and exhaust
# RAM on memory-constrained boxes. Point TMPDIR at real disk instead.
if [[ "$(uname)" == "Linux" ]]; then
  export TMPDIR="${XDG_CACHE_HOME}/tmp"
  mkdir -p "$TMPDIR" 2>/dev/null
fi

# Zsh cache/history locations
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
mkdir -p "$ZSH_CACHE_DIR" "$(dirname "$HISTFILE")" >/dev/null 2>&1

# Color/theme defaults
# Cache LS_COLORS — only regenerate if vivid binary is newer than cache
_vivid_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/ls_colors"
if [[ ! -f "$_vivid_cache" || "$(command -v vivid)" -nt "$_vivid_cache" ]]; then
  vivid generate one-dark >| "$_vivid_cache" 2>/dev/null
fi
[[ -f "$_vivid_cache" ]] && export LS_COLORS=$(<"$_vivid_cache")
unset _vivid_cache

# History settings
# NOTE: HISTORY_SECRET should be set in local ~/.config/zsh/secrets.zsh
# See dot_config/zsh/secrets.example.zsh for source reference.
HISTSIZE=6969420
SAVEHIST=6969420

# Misc tool defaults (portability improved)
[[ -n "${BREW_PREFIX:-}" ]] && export GSETTINGS_SCHEMA_DIR="${BREW_PREFIX}/share/glib-2.0/schemas"
export STARSHIP_CACHE=${STARSHIP_CACHE:-$HOME/.starship/cache}
export FZF_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/fzf"

# SSH sessions get a clearer, warmer ops-oriented palette so remote shells stand
# out from local work at a glance.
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship-remote.toml"
  export LS_COLORS='di=1;36:ln=1;35:so=1;31:pi=0;33:ex=1;32:bd=1;33:cd=1;33:su=1;37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:mi=1;31:or=1;31'
  export BAT_THEME="${BAT_THEME:-Monokai Extended Bright}"
fi

# Helix can be installed as a standalone binary without its runtime bundle.
# Prefer an explicit runtime directory only when it contains the full assets.
if [[ -z "${HELIX_RUNTIME:-}" ]]; then
  _helix_runtime_candidates=(
    "/snap/helix/current/bin/runtime"
    "${XDG_DATA_HOME:-$HOME/.local/share}/helix/runtime"
    "${BREW_PREFIX:+${BREW_PREFIX}/share/helix/runtime}"
    "/usr/local/share/helix/runtime"
    "/usr/share/helix/runtime"
  )
  for _helix_runtime in "${_helix_runtime_candidates[@]}"; do
    if [[ -n "$_helix_runtime" && -d "$_helix_runtime/queries" && -d "$_helix_runtime/themes" ]]; then
      export HELIX_RUNTIME="$_helix_runtime"
      break
    fi
  done
  unset _helix_runtime _helix_runtime_candidates
fi
