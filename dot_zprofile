# Login-shell package manager bootstrap; keep recurring PATH edits in `paths.zsh`.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi




##
# Your previous /Users/ivan/.zprofile file was backed up as /Users/ivan/.zprofile.macports-saved_2026-03-16_at_10:52:51
##

if [[ "$(uname)" == "Darwin" ]]; then
  # MacPorts
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
  # Obsidian CLI
  export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
fi
