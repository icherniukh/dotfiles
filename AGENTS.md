# Dotfiles Plan & Status (Stow)

Goal: a transparent, GNU Stow-managed dotfiles repo that’s safe to publish (no secrets) and easy to share.

- [x] Create stow repo layout (`~/proj/dotfiles-stow`)
- [x] Copy current configs into stow packages (excluding `secrets.zsh`, `local.zsh`, scratch files)
- [x] Add documentation (`README.md`, `INVENTORY.md`, `MIGRATION.md`, `SECURITY.md`)
- [x] Run portability + secret audits (removed absolute `/Users/...` paths; quick token scan)
- [ ] Decide GitHub strategy (new repo/branch vs replace existing `dotfiles`)
- [x] Migrate `$HOME` to stow symlinks (move-aside backups created; stow applied)
- [ ] Archive/retire yadm setup after validation

Notes
- App packages are also stowed (`wez ghostty helix lazygit lsd ripgrep starship procs yazi`).
- Stow initially reports conflicts because `$HOME` contains real files; use `stow -n` + move-aside or `stow --adopt`.
- Keep real secrets in `~/.config/zsh/secrets.zsh` (local-only).
- The accidental `_xone-k2-translator` completion was removed and purged from `dotfiles-stow` git history.
