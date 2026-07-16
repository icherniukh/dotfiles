# Modern dynamic loading (disables native fzf tab completion so fzf-tab can take over)
source <(fzf --zsh | grep -v 'completion.zsh')

# Use `fd` instead of the default `find` to respect .gitignore and skip .git/
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# --- BACKUP of previous Root Loops styling ---
# export FZF_DEFAULT_OPTS="  --color=fg:#e7ebf6,fg+:#f5f6fb,bg:#1a2137,bg+:#2e3859 \
# --color=hl:#28c8b1,hl+:#30e1c7,info:#f49437,marker:#a1bd22 \
# --color=prompt:#fb80aa,spinner:#bd97fc,pointer:#bd97fc,header:#56b8f7 \
# --color=border:#586899,label:#bcc6e3,query:#e7ebf6"
# export FZF_CTRL_R_OPTS="--no-sort --exact --bind 'ctrl-r:toggle-sort'"

# --- NEW Modern Styling (Sleek, Catppuccin-inspired with Rounded Borders) ---
export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border=rounded \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --bind 'ctrl-/:toggle-preview'"

# Add a toggleable preview window for long commands in history (press Ctrl-/)
# We add --with-nth=1.. to override fzf's default hiding of history line numbers
export FZF_CTRL_R_OPTS="--no-sort --exact --with-nth=1.. \
  --preview 'echo {}' --preview-window down:3:hidden:wrap \
  --bind 'ctrl-/:toggle-preview'"
