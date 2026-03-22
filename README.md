# Dotfiles (GNU Stow)

Transparent, symlink-based dotfiles managed with GNU Stow.

## Install

```bash
brew install stow
```

## Usage

```bash
# Dry run
stow -nvt ~ zsh git fzf scripts

# Apply
stow -vt ~ zsh git fzf scripts

# Remove
stow -Dvt ~ zsh
```

### Packages

Core:
- `zsh/` → `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.profile`, `~/.config/zsh/*`
- `git/` → `~/.gitconfig`, `~/.git-themes`
- `fzf/` → `~/.config/fzf/fzf.zsh`
- `scripts/` → `~/.scripts/*`

Optional app configs:
- `wez/` → `~/.config/wezmux.zsh`, `~/.config/wezaliases.zsh`
- `ghostty/` → `~/.config/ghostty/*`
- `helix/` → `~/.config/helix/*`
- `lazygit/` → `~/.config/lazygit/config.yml`
- `lsd/` → `~/.config/lsd/config.yml`
- `ripgrep/` → `~/.config/ripgrep/config`
- `starship/` → `~/.config/starship.toml`
- `procs/` → `~/.config/procs.toml`
- `yazi/` → `~/.config/yazi/*`

### First-time setup

1. `stow -nvt ~ zsh` and inspect conflicts
2. Move conflicting files aside, or use `stow --adopt -vt ~ zsh`

### Secrets / machine-local

Do not commit secrets. Use templates:
- `~/.config/zsh/secrets.zsh` ← `zsh/.config/zsh/secrets.example.zsh`
- `~/.config/zsh/local.zsh` ← `zsh/.config/zsh/local.example.zsh`

### Convention

Each top-level folder is a stow package, with paths relative to `$HOME`.
