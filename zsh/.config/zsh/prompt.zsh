# Starship's zsh init defines zle widgets, so only load it when a real TTY is attached.
if [[ -t 0 && -t 1 ]]; then
  eval "$(starship init zsh)"
fi
