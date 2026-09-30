# Architecture & Configuration Decision Log

This log tracks architectural decisions, technical choices, configuration shifts, and reversions made in this dotfiles repository.

---

## Record Format
Each entry contains:
- **ID**: Sequential number (e.g., `ADR-001`)
- **Date**: YYYY-MM-DD
- **Status**: `Accepted` | `Reverted` | `Superseded`
- **Context**: The problem or requirement prompting the decision
- **Decision**: What was changed, kept, or removed
- **Consequences**: Technical benefits, trade-offs, and invariants enforced

---

## Log Entries

### ADR-001: Decision Log System
- **Date**: 2026-08-07
- **Status**: Accepted
- **Context**: Need a durable, explicit system to log every design choice, configuration change, and reversion across dotfiles maintenance.
- **Decision**: Established `DECISIONS.md` as the single source of truth for architectural decisions in this repository.
- **Consequences**: Every major change or reversion must be logged with context, rationale, and technical consequences.

### ADR-002: Revert `fzf-tab` in Favor of Classic Zsh Completion + Carapace
- **Date**: 2026-08-07
- **Status**: Accepted (Reverts earlier `fzf-tab` adoption)
- **Context**: `fzf-tab` introduced complexity, keybinding collisions with ZLE and `zsh-autosuggestions`, layout flickering, and fragile plugin dependencies.
- **Decision**:
  - Remove `Aloxaf/fzf-tab` from `dot_zsh_plugins.txt`.
  - Configure classic native Zsh completion (`compinit` + `zstyle ':completion:*' menu select`) with rich formatting, matcher-list case-insensitivity, and group headers in `completion.zsh`.
  - Retain `carapace` for universal CLI flag/subcommand spec definitions.
  - Keep `fzf` strictly for interactive search widgets (`ctrl-r` history, `ctrl-t` file finder, `alt-c` cd navigation).
  - Update `run_before_apply-guard` to enforce that neither `fzf-tab` nor `zsh-autocomplete` are present in `dot_zsh_plugins.txt`.
- **Consequences**: Faster shell startup, zero ZLE widget conflicts, clean native arrow-key menu grid, predictable Tab behavior.

### ADR-003: Yazi Plugins Follow `ya pkg`, Then Sync to Chezmoi
- **Date**: 2026-09-21
- **Status**: Accepted
- **Context**: Yazi 26.9.1 left `git` fetcher tasks running forever, so every quit asked "There are unfinished tasks, quit anyway?". Chezmoi was holding older plugin code (git, diff, vcs-files, mime-ext, full-border built for 25.x) while `package.toml` pinned `babfd0f`. Each `chezmoi apply` put the old code back over the version `ya` had installed.
- **Decision**:
  - Upgraded those five plugins with `ya pkg upgrade --discard` (to `f703392`). The discarded "local changes" were older upstream code, not custom edits.
  - After any `ya pkg install/upgrade`, run `chezmoi add ~/.config/yazi/package.toml ~/.config/yazi/plugins/<name>.yazi` so the source matches what `ya` deployed.
  - `ya` deploys plugin files read-only, so chezmoi stores them as `readonly_*`.
  - Added flavor `kanagawa-contrast` (kanagawa with lighter folder names). `theme.toml` `[filetype]` rules override the flavor's, so the folder color is set in both.
- **Consequences**: No more hung fetchers or quit prompt. The plugin code in chezmoi now matches the `package.toml` pins. Changing plugins in the live dir without `chezmoi add` will be reverted by the next apply.

### ADR-004: tmux Config Under Chezmoi, Lean Plugin Set
- **Date**: 2026-09-22
- **Status**: Superseded by ADR-005 (theme, plugin set, tpm source); mouse/scroll behaviour kept
- **Context**: `~/.config/tmux/tmux.conf` was not managed by chezmoi. It loaded 12 plugins (dracula, treemux, sidebar, menus, fzf, which-key, pain-control…), and wheel scrolling and mouse selection didn't behave like a plain terminal.
- **Decision**:
  - `dot_config/tmux/tmux.conf` is the only tracked tmux file. Plugins install into `~/.config/tmux/plugins` via Homebrew TPM (`/opt/homebrew/opt/tpm`) and stay untracked; missing plugins are installed on first server start.
  - Plugins: `tmux-ukiyo` (status themes, kanagawa/wave to match yazi), `tmux-resurrect`, `tmux-continuum` (autosave only, no auto-restore). Common options are set directly instead of via `tmux-sensible`.
  - Prefix `C-b`. Mouse wheel passes through to apps with mouse support, sends arrow keys to full-screen apps without it (less, man), and opens scrollback in the shell (exits at the bottom). Drag-select copies to the macOS clipboard.
- **Consequences**: Old config and plugins kept as `~/.config/tmux/*.bak-20260922` (untracked). Stale `~/.config/tmux/config` and `~/.config/tmux/.tmux.conf` are not loaded by tmux.

### ADR-005: Merge Remote-Host Branch (origin/main) With Mac Branch
- **Date**: 2026-09-30
- **Status**: Accepted
- **Context**: `origin/main` (edited on the Linux VPS, used from a phone over Moshi/mosh) and local `main` (macOS workstation) diverged for three months: 10 vs 22 commits, 12 conflicting files. Upstream had better portability (existing-dirs-only PATH, per-OS chezmoi templates, tpm as an external, tests); local had the Mac shell fixes (antidote-owned plugins, compinit after plugins, clean `.zshenv`) and the safety tooling (apply-guard, hk + gitleaks, history backup).
- **Decision**:
  - Branch from `origin/main` and merge local `main` so both histories are kept.
  - PATH: upstream's managed/exists-only rebuild. Runtimes: `mise activate` when mise exists; pyenv/fnm/ruby-gem/bun setup only as a fallback on hosts without mise.
  - Plugins: antidote owns autosuggestions, syntax-highlighting, history-substring-search and forgit on every OS (no Homebrew/distro double source). Keeps upstream's `fzf-zsh-plugin`, `zsh-completions`, npm completion; `fzf.zsh` is sourced once (by the plugin when present).
  - Completion: plugins load only with a TTY; compinit runs after them in every interactive shell, full rebuild when the dump is missing, older than 24h or `bd` completion was regenerated, then `zcompile`; otherwise `compinit -C`.
  - tmux: upstream's Moshi-aware graphite/apricot theme (status-left carries the essentials, bar on top), extrakto, which-key, tpm from `.chezmoiexternal.toml`. Added from ADR-004: terminal-like wheel/drag-copy, vi copy keys, pane nav/resize, ghostty terminal features, `pbcopy` when available, `@continuum-restore off` on macOS. tmux-ukiyo dropped: it rewrites the status line Moshi depends on.
  - Beads: repo config keeps both `sync.remote` and `no-git-ops: true`; global `~/.config/bd/config.yaml` adds `no-git-ops: true` to upstream's defaults.
  - Yazi bookmarks: `~/proj`, `~/repos`, `~/Downloads` added only when they exist.
  - Tests: upstream's `tests/` kept, made bash-3.2 safe, and extended with checks for the local invariants above.
- **Consequences**: One config for Mac and remote hosts. The Linux side of the templates was not exercised on this machine. On first apply, chezmoi starts managing `~/.claude/statusline.sh`, `~/.config/bd/config.yaml`, `~/.config/tmuxinator/` and clones tpm into `~/.config/tmux/plugins/tpm`; the Homebrew tpm path is no longer used.
