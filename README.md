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

## Weekly history backups

Both platforms use `~/.scripts/backup-zsh-history-weekly` to save private gzip
archives under `~/.backups/zsh-history/` on Sundays at noon, local time.
macOS uses the LaunchAgent; Linux uses a systemd user timer. Each scheduler is
excluded on other operating systems.

On Linux, a full `chezmoi apply` installs the backup files, reloads the systemd
user manager, and enables/starts the timer automatically through a Linux-only
`run_after_` script. It is safe to rerun. When systemd or a user session is
unavailable, activation is skipped with a message and retried on the next apply.
Other systemctl failures fail the apply instead of being silently ignored.

```bash
chezmoi apply
systemctl --user list-timers zsh-history-backup.timer
```

`Persistent=true` catches up on missed runs when the user manager starts again.
User timers normally run only while logged in; if backups must run while logged
out, an administrator can enable lingering with `loginctl enable-linger "$USER"`.
Logs are available via `journalctl --user -u zsh-history-backup.service`.
On Linux without systemd, schedule the same backup script using your scheduler
of choice. A scoped apply of individual backup files does not run the root
after-script; use a full apply to activate the timer.

## Daily use

```bash
chezmoi diff        # preview pending changes
chezmoi apply       # apply changes
chezmoi cd          # open source directory
chezmoi add <file>  # track a new file
```

## Dynamic aliases

Use `addalias gp 'git push'` and enter a description; `lsa` lists these aliases.
They live only in `${XDG_CONFIG_HOME:-~/.config}/zsh/user-aliases.zsh`, separate
from the static aliases. New aliases work immediately and in new shells.
Minor edits to that file are fine; use `source ~/.zshrc` to reload them.

Chezmoi creates this private file once and preserves subsequent additions.
Its contents are local to each machine; copy it explicitly when moving aliases.
Do not `chezmoi re-add` it as part of normal drift reconciliation: its create-only
source is a seed, not a synchronized copy of the runtime data.

## Development

- Run `hk-dotfiles-secrets` inside this repository to scan for leaked secrets before pushing. It securely tests changes using a staging directory to prevent false positives from local AI caches.
- Focused regression checks (no tool/plugin installs):
  ```bash
  mise exec -- python tests/zsh_alias_check.py
  mise exec -- python tests/zsh_fig_check.py
  mise exec -- python tests/hk_staging_check.py
  mise exec -- python tests/mise_postinstall_check.py
  python3 tests/mise_host_config_check.py
  python3 tests/artifact_save_check.py
  python3 tests/zsh_plugin_bundle_check.py
  mise exec -- bash tests/zsh_completion_check.sh
  mise exec -- python tests/zsh_completion_ui.py
  ```
  The UI check needs installed Zsh, tmux, fzf, Claude, Composio,
  zsh-autosuggestions, zsh-history-substring-search and history-search-multi-word.
  If a plugin is outside Antidote's default cache, point `ZSH_AUTOSUGGESTIONS_FILE`,
  `ZSH_HISTORY_SUBSTRING_SEARCH_FILE` or `ZSH_HISTORY_SEARCH_MULTI_WORD_DIR` at it.
  Both completion checks use temporary HOME/XDG paths
  and controlled configuration; `zsh_completion_check.sh --live` is an explicit
  opt-in to inspect your deployed shell instead.

## Runtime migration

`~/.config/mise/conf.d/00-shared.toml` keeps the VPS runtime baseline. Put
workstation-specific versions and tools in `~/.config/mise/conf.d/host.toml`,
which stays local to each host and is
excluded from chezmoi deployment. Install and verify new runtimes before selecting
them there; pulling these dotfiles does not install replacements. The shared
Ruby postinstall hook requires `jq` and fails clearly if it is unavailable.
Keep tool selections out of the global `config.toml`: it takes precedence over
the `conf.d` files and would prevent host-local runtime overrides.
`mise use -g` writes to `host.toml` through `[settings.write_targets]`.

Use `docs/runtime-transition.html` as the local dashboard while moving runtimes and CLI ownership to mise/uv.

## Notes

- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `executable_` sets executable bit; `symlink_` creates a symlink
- `.tmpl` files are rendered as Go templates at apply time (`.chezmoi.os` etc.)
- `secrets.zsh` and `local.zsh` are gitignored — never committed
- macOS-only configs (`ghostty`, `hammerspoon`) are excluded on Linux via `.chezmoiignore`
