# Dotfiles (chezmoi)

Personal dotfiles managed with chezmoi.

## Install

```bash
brew install chezmoi
chezmoi init --source ~/proj/dotfiles-stow
```

## Usage

```bash
# Inspect pending changes
chezmoi status
chezmoi diff

# Apply
chezmoi apply

# Edit the source tree
chezmoi cd
```

### Managed Paths

Core:
- `dot_zshrc`, `dot_zprofile`, `dot_zshenv`, `dot_profile` -> shell startup files in `$HOME`
- `dot_config/zsh/` -> `~/.config/zsh/`
- `dot_gitconfig`, `dot_git-themes` -> Git config and themes
- `dot_config/fzf/` -> `~/.config/fzf/`
- `dot_scripts/` -> `~/.scripts/`

Optional app configs:
- `dot_config/ghostty/` -> `~/.config/ghostty/`
- `dot_config/helix/` -> `~/.config/helix/`
- `dot_config/lazygit/` -> `~/.config/lazygit/`
- `dot_config/lsd/` -> `~/.config/lsd/`
- `dot_config/ripgrep/` -> `~/.config/ripgrep/`
- `dot_config/starship.toml` -> `~/.config/starship.toml`
- `dot_config/procs.toml` -> `~/.config/procs.toml`
- `dot_config/yazi/` -> `~/.config/yazi/`
- `dot_hammerspoon/` -> `~/.hammerspoon/`

### First-time setup

1. Run `chezmoi diff` and inspect conflicts.
2. Move conflicting files aside or import them deliberately with `chezmoi add`.
3. Run `chezmoi apply`.

### Secrets / machine-local

Do not commit secrets. Use templates:
- `~/.config/zsh/secrets.zsh` from `dot_config/zsh/secrets.example.zsh`
- `~/.config/zsh/local.zsh` from `dot_config/zsh/local.example.zsh`

Actual local files are intentionally ignored in the source tree.

### Convention

chezmoi source names map to home-directory paths: `dot_` becomes `.`, `executable_` sets executable mode, `readonly_` sets read-only mode, and `symlink_` creates a symlink whose target is the file content.
