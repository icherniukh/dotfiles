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
- **Status**: Superseded in part by ADR-005 (plugin set, tpm source); mouse/scroll behaviour kept; ukiyo later dropped everywhere (ADR-005)
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
  - tmux: upstream's Moshi-aware graphite/apricot theme (status-left carries the essentials, bar on top), extrakto, which-key, tpm from `.chezmoiexternal.toml`. Added from ADR-004: terminal-like wheel/drag-copy, vi copy keys, pane nav/resize, ghostty terminal features, `pbcopy` when available, `@continuum-restore off` on macOS. tmux-ukiyo dropped on remote hosts (it rewrites the status line Moshi depends on) but kept on macOS: `tmux.conf.tmpl` renders ukiyo (kanagawa/wave, bar at the bottom) on darwin and the graphite/apricot theme elsewhere.
  - Beads: repo config keeps both `sync.remote` and `no-git-ops: true`; global `~/.config/bd/config.yaml` adds `no-git-ops: true` to upstream's defaults and sets `export.git-add: false` so bd never stages files itself.
  - `tmuxinator/ops.yml` (systemctl/journalctl) is deployed only on Linux.
  - macOS theme (2026-10-01): tmux-ukiyo dropped on macOS too; every host renders graphite/apricot with the bar on top. kanagawa/wave was too low-contrast: session block 3.6:1, window flags 1.9:1, bar 1.16:1 against the panes. The idle `[sN]` colour went from muted #7c7e86 (3.5:1) to text #a3a5ad (5.8:1).
  - Status bar (2026-10-06): upstream's compact `[sN]` left / host-colour swatch right kept; a per-host Nerd Font icon on the left was tried and dropped. Restored from upstream: `M-Space` which-key on non-macOS, `monitor-activity on`/`visual-activity off` on every OS. tmux-ukiyo's prefix-T menu saves choices to `plugins/tmux-ukiyo/data/.tmux-ukiyo-state`, which overrides `tmux.conf`; a stale `dracula/classic` entry there is why kanagawa never showed after the merge.
  - Yazi bookmarks: `~/proj`, `~/repos`, `~/Downloads` added only when they exist.
  - Tests: upstream's `tests/` kept, made bash-3.2 safe, and extended with checks for the local invariants above.
- **Consequences**: One config for Mac and remote hosts. The Linux side of the templates was not exercised on this machine. On first apply, chezmoi starts managing `~/.claude/statusline.sh`, `~/.config/bd/config.yaml`, `~/.config/tmuxinator/` and clones tpm into `~/.config/tmux/plugins/tpm`; the Homebrew tpm path is no longer used.

### ADR-006: First Full Apply on the VPS After the ADR-005 Merge
- **Date**: 2026-10-15
- **Status**: Accepted
- **Context**: The VPS hadn't run a full `chezmoi apply` since the merge in ADR-005. About 60 targets had drifted. Most were simply behind the repo, a few had live edits, and the live mise config pinned host-only tools (beads, helix, herdr, yazi) that the shared config drops.
- **Decision**:
  - Host-only mise tools go in `~/.config/mise/conf.d/host.toml` (untracked); the managed `config.toml` stays shared across machines.
  - Live-only edits carried into the source: the stale-`HELIX_RUNTIME` guard (`env.zsh`), `bat=batcat` (new `aliases.linux.zsh`), the Obsidian CLI path (`paths.darwin.zsh`), and the newer `beads-slim` and `statusline-desktop.sh`.
  - `audit-runtimes` treats package managers in `/usr/bin` (corepack shims) as system-owned warnings, like system Python. Stale `npm:yarn` uninstalled from mise.
  - `hk-chezmoi-staging` skips gitignored files and the gitleaks step's exclude globs, since gitleaks runs with `--source .`. The gitignored `secrets.zsh` was blocking every apply.
  - The phone's Claude statusline uses `MOSHI_CLIENT=1`, exported from the untracked `~/.config/zsh/local.zsh`. Moshi attaches tmux via `sh -lc`, so zsh never runs first and the `env.zsh` recovery can't fire.
- **Consequences**: The rustup stable toolchain was reinstalled through mise (its manifest was corrupt). `colorls` now comes from mise's `gem:colorls`.
