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
   - `stow -nvt ~ zsh git fzf scripts completions`
5. Resolve conflicts:
   - move conflicting files aside (recommended), then run again, or
   - `stow --adopt -vt ~ <package>` to convert existing real files into repo files + symlinks.
6. Apply:
   - `stow -vt ~ zsh git fzf scripts completions`

## After migration

- Use git in this repo normally (`git status`, `git commit`, `git push`).
- Stow again after adding/removing files in packages.
- Once you’re confident, you can stop using yadm (and later archive/remove it).

