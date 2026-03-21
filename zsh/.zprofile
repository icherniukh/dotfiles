
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.pre.zsh"

eval "$(/opt/homebrew/bin/brew shellenv)"



# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.post.zsh"

##
# Your previous /Users/ivan/.zprofile file was backed up as /Users/ivan/.zprofile.macports-saved_2026-03-16_at_10:52:51
##

# MacPorts Installer addition on 2026-03-16_at_10:52:51: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.


# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
