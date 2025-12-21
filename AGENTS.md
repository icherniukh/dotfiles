# Dotfiles Plan & Status (Stow)

Goal: a transparent, GNU Stow-managed dotfiles repo that’s safe to publish (no secrets) and easy to share.

- [x] Create stow repo layout (`~/proj/dotfiles-stow`)
- [x] Copy current configs into stow packages (excluding `secrets.zsh`, `local.zsh`, scratch files)
- [x] Add documentation (`README.md`, `INVENTORY.md`, `MIGRATION.md`, `SECURITY.md`)
- [x] Run portability + secret audits (removed absolute `/Users/...` paths; quick token scan)
- [ ] Decide GitHub strategy (new repo/branch vs replace existing `dotfiles`)
- [ ] Migrate `$HOME` to stow symlinks (dry-run, resolve conflicts, apply)
- [ ] Archive/retire yadm setup after validation

Notes
- Stow will initially report conflicts because `$HOME` currently contains real files; use `stow -n` + move-aside or `stow --adopt`.
- Keep real secrets in `~/.config/zsh/secrets.zsh` (local-only).
