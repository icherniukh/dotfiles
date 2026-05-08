# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

## Bootstrap

**macOS**
```bash
brew install chezmoi
chezmoi init --apply git@github:icherniukh/dotfiles.git
```

**Debian/Linux**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github:icherniukh/dotfiles.git
```

After applying, copy the example files for machine-local config:
```bash
cp ~/.config/zsh/secrets.example.zsh ~/.config/zsh/secrets.zsh
cp ~/.config/zsh/local.example.zsh ~/.config/zsh/local.zsh
```

## Daily use

```bash
chezmoi diff        # preview pending changes
chezmoi apply       # apply changes
chezmoi cd          # open source directory
chezmoi add <file>  # track a new file
```

## Notes

- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `executable_` sets executable bit; `symlink_` creates a symlink
- `.tmpl` files are rendered as Go templates at apply time (`.chezmoi.os` etc.)
- `secrets.zsh` and `local.zsh` are gitignored — never committed
- macOS-only configs (`ghostty`, `hammerspoon`) are excluded on Linux via `.chezmoiignore`
