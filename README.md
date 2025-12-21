# Dotfiles (GNU Stow)

This repo is a transparent, symlink-based dotfiles setup using GNU Stow.

## Why Stow

- Stow only touches files when you run it (no “ignore my whole `$HOME`” problem).
- The result is just symlinks you can `ls -la` and reason about.

## Install

- macOS (Homebrew): `brew install stow`

## Usage

From the repo root:

- Dry run: `stow -nvt ~ zsh git fzf scripts`
- Apply: `stow -vt ~ zsh git fzf scripts`
- Remove: `stow -Dvt ~ zsh`

Optional packages: `wez ghostty helix lazygit lsd ripgrep starship procs yazi` (see `INVENTORY.md`).

### First-time setup (safe)

1. Run `stow -nvt ~ zsh` and inspect any conflicts.
2. If a file already exists, either:
   - move it aside (recommended), then re-run stow, or
   - use adoption: `stow --adopt -vt ~ zsh` (moves the existing file into the repo, then replaces it with a symlink).

See `MIGRATION.md` for switching from the current yadm setup.

## Secrets / machine-local config

- Do not commit secrets.
- Create `~/.config/zsh/secrets.zsh` (not tracked) using `zsh/.config/zsh/secrets.example.zsh` as a template.
- Create `~/.config/zsh/local.zsh` (not tracked) using `zsh/.config/zsh/local.example.zsh` as a template.

Local-only notes/snapshots can live under `local/` (ignored by git).

## Repo conventions

- Packages are top-level directories (`zsh/`, `git/`, …).
- Inside each package, paths are relative to `$HOME` (e.g. `zsh/.config/zsh/...`).

## Important paths

- `~/.config/zsh/` — zsh modules (`env.zsh`, `plugins.zsh`, `aliases.zsh`, `functions.zsh`, …)
- `~/.config/zsh/secrets.zsh` — real secrets (local-only; not in git)
- `~/.config/zsh/local.zsh` — per-machine overrides (local-only; not in git)
- `~/.scripts/` — your scripts (tracked); synced into `~/.local/bin` by `~/.config/zsh/sync-scripts.zsh`
- `~/.gitconfig` / `~/.git-themes` — git config and theme include
