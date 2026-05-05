#!/usr/bin/env zsh

# Alias management
# auto-completion/suggestion

# Editing configs

alias hz='hx ~/.zshrc'
alias hxal='hx ~/.config/zsh/aliases.zsh'

function _hxx() { touch "$1" && chmod +x "$1" && hx "$1"; }
alias hxx='_hxx'

alias goconfig='pushd ~/.config'

alias srcshell='usource ~/.zshrc'
alias refreshenv='source ~/.zshrc'
alias okay='source ~/.zshrc'

function _mkcd() { mkdir -p "$1" && pushd "$1"; }
alias mkcd='_mkcd'

alias yfind="find . -type f -print0 | xargs -0 grep $@"

# File listing aliases
alias ls='eza -hF --icons=always --time-style relative --color=auto --no-permissions --no-user --classify --color-scale=age --git'
alias lz='eza -l --no-user --no-permissions --time-style relative --color=always --color-scale-mode=fixed -1 --icons=always --git-repos --git'
alias l='lsd --blocks=git,date,size,name -trG --classify --no-symlink'
alias ld='lsd --icon-theme fancy -Fh --date=relative --no-symlink'
alias ll='lsd -l -NFL'
alias la='lsd -ALhg --date relative --no-symlink --permission disable'
alias lla='lsd -lahFGg --date relative --no-symlink'
alias lr='lsd --color auto --icon-theme fancy -FLg --tree --depth=2 --no-symlink'
alias lrr='lsd --color auto --icon-theme=fancy -FLg --tree --depth=3 --no-symlink'
alias lt='lsd --blocks=date,size,name -tr --classify --no-symlink'

# Utils
alias cls='clear'
alias hg='history 0|grep'
alias grep='grep --color=auto'
alias rg='rg -S'
alias ip='ip --color=auto'
alias fgrep='fgrep --color=auto'

# Quick-add added aliases
# alias gh='ghostty'
function xrand() {
  local ans=$((RANDOM%($1+1)))
  echo $ans
}

# alias fconf="zellij run -c -f -x 50% -y 10% --width 45% --height 70% -- yazi $HOME/.config"
alias lol='lolcat -S 255 -F 0.5 -s 10 -p 5 -a -i'

function addtask() {
  cp ~/.tasks ~/.tasks.last.bak
  echo "$@" >> ~/.tasks
}

alias lg=lazygit

# alias gimain="git checkout mainline"
# alias maindeepclean="git pull origin mainline:mainline"
# alias updmain=maindeepclean

alias gitw='git-workspace'
alias qt='kiro-cli translate'
alias qc='kiro-cli chat'

alias qconfig='hx -w ~/.aws/amazonq ~/.aws/amazonq/global_context.json ~/.aws/amazonq/mcp.json'

# ------------------------------------------------------------------------------
#  Convenience Aliases (imported)
# ------------------------------------------------------------------------------

# List user-added aliases with descriptions (added via `addalias`)
lsa() {
    echo "Custom Aliases (${HOME}/.config/zsh/aliases.zsh)"
    echo "-------------------------------------------------"
    awk '
      BEGIN { FS = "="; in_section = 0; comment = "" }
      /^# >>> USER ALIASES >>>$/ { in_section = 1; next }
      in_section == 0 { next }
      /^# / { comment = substr($0, 3); next }
      /^alias / {
        name = $1
        sub(/^alias /, "", name)
        if (comment == "") comment = "-"
        printf "% -25s - %s\n", name, comment
        comment = ""
      }
    ' "$HOME/.config/zsh/aliases.zsh"
}

# List all running processes
alias psg='ps aux | grep'

# Homebrew-specific aliases (only when brew is available)
if command -v brew >/dev/null 2>&1; then
  # Search for brew packages by keyword in their description
  alias brew-discover='brew search --desc --eval-all'
  # list all packages installed with brew with short descriptions
  alias brew-installed='brew_installed'
  alias bs='brew search'
  alias bi='brew info'
  alias bsd='brew search --desc'
fi

# claude for laziest
alias cla='claude'

# ya
alias c1='sherlock'

# antigravity.google
alias ag='antigravity'

# kiro-cli shortcut
alias qq='kiro-cli'
alias kira='kiro-cli'
alias kiro='kiro-cli'

# docker = opposite of intuitive
alias lzdock='lazydocker'

# stylish csv table printing
alias csvcat='tennis'

# macOS-only aliases
if [[ "$(uname)" == "Darwin" ]]; then
  # File managers
  alias nimble="open -a 'Nimble Commander'"
  alias bloom="open -a Bloom"
  alias marta="open -a Marta"
  # Opens GUI Finder in current folder
  alias finder='open -R .'
  # List all Ghostty theme names
  alias ghthemes='lsd -1N --icon never /Applications/Ghostty.app/Contents/Resources/ghostty/themes/'
  # Logic Pro samples
  alias gotosamples='cd "/Library/Application Support/Logic/Ultrabeat Samples/Epic Electro/"'
fi

# Fuzzy-select Github PR to checkout
alias gh-prcheckout='gh pr list | fzf | awk '\''{print }'\'' | xargs gh pr checkout'

# Codex, duh
alias cx='codex'

# exiftool ALL
alias xif='exiftool -a -u -g -ee -api largefilechunks=1'

# list usbs via diskutil
alias usblist='diskutil list | grep -i external'
