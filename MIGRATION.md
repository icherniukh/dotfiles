# Migration notes (yadm → stow)

This repo is meant to replace the current yadm-in-`$HOME` setup with explicit symlinks.

## Current situation

- yadm worktree: `$HOME`
- yadm bare repo (internal): `~/.local/share/yadm/repo.git`

## Recommended migration flow

1. Make sure yadm is clean:
   - `yadm status`
2. Keep yadm as a safety net for now (do not delete it yet).
3. Clone this repo somewhere (example):
   - `git clone git@github.com:icherniukh/dotfiles.git ~/proj/dotfiles-stow`
4. Dry-run stow packages you want:
   - `cd ~/proj/dotfiles-stow`
   - `stow -nvt ~ zsh git fzf scripts`
5. Resolve conflicts:
   - move conflicting files aside (recommended), then run again, or
   - `stow --adopt -vt ~ <package>` to convert existing real files into repo files + symlinks.
6. Apply:
   - `stow -vt ~ zsh git fzf scripts`

Notes

- `~/.git-themes` is commonly a pre-existing symlink (from the old setup). If stow reports “not owned by stow”, move it aside first (or remove it) and re-run stow for the `git` package.
- If you keep secrets at `~/.config/zsh/secrets.zsh`, keep the `~/.config/zsh/` directory real and let stow link only the tracked files inside it.

## Rollback (if something breaks)

1. Remove links: `cd ~/proj/dotfiles-stow && stow -Dvt ~ zsh git fzf scripts`
2. Restore your moved-aside files from `~/proj/dotfiles-stow/local/pre-stow-*/` back into `$HOME`.

## After migration

- Use git in this repo normally (`git status`, `git commit`, `git push`).
- Stow again after adding/removing files in packages.
- Once you’re confident, you can stop using yadm (and later archive/remove it).
