# SSH sessions get a darker terminal backdrop and warm cursor so remote shells
# read differently before you even see the prompt.
if [[ -n "${SSH_CONNECTION:-}" && -t 0 && -t 1 ]]; then
  _emit_osc() {
    if [[ -n "${TMUX:-}" ]]; then
      printf '\033Ptmux;\033\033]%s\007\033\\' "$1"
    elif [[ "${TERM:-}" == screen* ]]; then
      printf '\033P\033]%s\007\033\\' "$1"
    else
      printf '\033]%s\007' "$1"
    fi
  }

  _emit_osc '10;#e6d8c7'
  _emit_osc '11;#16111b'
  _emit_osc '12;#ffb86c'
  unset -f _emit_osc
fi

# Starship's zsh init defines zle widgets, so only load it when a real TTY is attached.
if [[ -t 0 && -t 1 ]]; then
  if [[ -n "${MOSH_CLIENT:-}" ]]; then
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship-mosh.toml"
  fi
  eval "$(starship init zsh)"
fi
