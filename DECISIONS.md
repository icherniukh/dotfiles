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
  - Beads: repo config keeps both `sync.remote` and `no-git-ops: true`; global `~/.config/bd/config.yaml` adds `no-git-ops: true` and `export.git-add: false` (the default). `no-git-ops` only changes `bd prime`'s close protocol (agents are told not to commit or push); it does not stop bd's own git activity. What keeps bd off git: `export.git-add: false`, `--stealth` init (no hooks, no agent files), `dolt.auto-push: false`.
  - Beads config files (2026-10-07): both are kept in the uncommented, key-sorted form bd writes. `bd config set` routes `sync.*`, `export.*`, `routing.*`, `no-git-ops` and similar keys into `config.yaml` and re-serializes it, dropping comments; reasons live here instead. Machine-only overrides go in `.beads/config.local.yaml` (not committed).
  - Beads gotcha: `import.auto` (default on) re-imports `.beads/issues.jsonl` into an empty database, and `export.auto` refreshes that file at most every `export.interval` (60s). Deleting the last issue can resurrect it; run `bd export -o .beads/issues.jsonl` after deleting from a nearly empty database.
  - Beads (2026-10-06): removed the untracked `~/proj/.beads -> dotfiles/.beads` symlink. bd walks up to it, so `bd init`/`bd config` in any `~/proj` repo without its own `.beads/` wrote dotfiles' workspace (rewrote `config.yaml`, inherited its remote and `dot` prefix). Such repos now get "no beads database found" until they run `bd init --stealth --prefix <name> --remote ""`. Cross-project/personal beads live in `~/proj/manager` (local git, stealth, prefix `manager`).
  - `tmuxinator/ops.yml` (systemctl/journalctl) is deployed only on Linux.
  - macOS theme (2026-10-01): tmux-ukiyo dropped on macOS too; every host renders graphite/apricot with the bar on top. kanagawa/wave was too low-contrast: session block 3.6:1, window flags 1.9:1, bar 1.16:1 against the panes. The idle `[sN]` colour went from muted #7c7e86 (3.5:1) to text #a3a5ad (5.8:1).
  - Status bar (2026-10-06): upstream's compact `[sN]` left / host-colour swatch right kept; a per-host Nerd Font icon on the left was tried and dropped. Restored from upstream: `M-Space` which-key on non-macOS, `monitor-activity on`/`visual-activity off` on every OS. tmux-ukiyo's prefix-T menu saves choices to `plugins/tmux-ukiyo/data/.tmux-ukiyo-state`, which overrides `tmux.conf`; a stale `dracula/classic` entry there is why kanagawa never showed after the merge.
  - Yazi bookmarks: `~/proj`, `~/repos`, `~/Downloads` added only when they exist.
  - Tests: upstream's `tests/` kept, made bash-3.2 safe, and extended with checks for the local invariants above.
- **Consequences**: One config for Mac and remote hosts. The Linux side of the templates was not exercised on this machine. On first apply, chezmoi starts managing `~/.claude/statusline.sh`, `~/.config/bd/config.yaml`, `~/.config/tmuxinator/` and clones tpm into `~/.config/tmux/plugins/tpm`; the Homebrew tpm path is no longer used.

### ADR-006a: First Full Apply on the VPS After the ADR-005 Merge
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

### ADR-006: Artifact Scripts (artifact-save, artifact, Raycast Script Command)
- **Date**: 2026-10-16
- **Status**: Accepted
- **Context**: Chat answers and agent output need a quick way into one folder (`~/ai_infra/artifacts/`) from the shell, from Raycast and from agent skills.
- **Decision**:
  - `dot_scripts/executable_artifact-save` writes stdin (or the clipboard on a TTY, or always with `-c`) to `<timestamp>-<name>.md`. `dot_scripts/executable_artifact` is a television picker over that folder, newest first. Folder override: `ARTIFACTS_DIR`.
  - The Raycast Script Command lives in `dot_config/raycast/scripts/` and only calls `~/.scripts/artifact-save -c`; Raycast has no TTY, so `-c` stops it from reading stdin. The directory is macOS-only (`.chezmoiignore`) and has to be added once under Raycast Settings → Extensions → Script Commands.
  - The `artifact_save` skill (`~/.claude/skills/`) and the List Artifacts extension (`~/proj/raycast_artifacts`) are not tracked here.
- **Consequences**: One implementation of the save logic. Raycast needs the dotfiles applied first.

### ADR-007: One Completion Initialization, Dismissible Menus
- **Date**: 2026-10-22
- **Status**: Accepted
- **Context**: Grok's installer appended `compinit -C` after shell initialization, replacing native and Carapace completion registrations. Long completion lists could spill into scrollback and remain visible after cancellation.
- **Decision**: Register Grok's completion directory before the existing `compinit` in `plugins.zsh`. Keep Carapace and native Codex/mise/uv initialization in managed `completion.zsh`; use Zsh's help-based flag completion for Claude and Composio. Open a scrollable selection menu on Tab. Escape clears the menu and history autosuggestion while keeping the current command editable.
- **Verification**: `bash tests/zsh_completion_check.sh` checks managed initialization; `bash tests/zsh_completion_check.sh --live` checks the final registrations after the actual `.zshrc`, including installer additions. Run the live check after CLI installers modify shell integration. `python3 tests/zsh_completion_ui.py` uses an isolated tmux server to exercise Escape, long option menus, and files created after an earlier completion attempt (requires tmux, Zsh, and the CLIs under test).
- **Consequences**: Host-only compdefs and Turbocharging's hook remain in `local.zsh`. Its duplicate native generators and filename-only Claude override were removed. Only Grok's redundant `fpath`/`compinit` lines were removed from the live `.zshrc`; pre-existing Kiro, Composio, and other live/source drift was preserved, so a whole-file apply of `.zshrc` still requires reconciliation. Claude/Composio completion covers flags and files; it does not supply semantic argument values or nested subcommands.

### ADR-008: History Retention, Contextual Suggestions, and fzf Search
- **Date**: 2026-10-22
- **Status**: Accepted
- **Context**: The active history was only 52 KB; `~/.zsh_history` points to the same file. macOS sets `SAVEHIST=1000` before user rc initialization, while the live Kiro pre-hook preceded the existing larger limits. The exact process responsible for the recent truncation was not established. `SHARE_HISTORY` and `INC_APPEND_HISTORY_TIME` were both enabled despite being mutually exclusive. Television's late initialization overrode Ctrl-R.
- **Decision**: Keep shared incremental history, explicit append/copy/locking, and remove the conflicting incremental modes. Preserve event order for `match_prev_cmd`, then fall back to recent history and completion for autosuggestions. Reassert fzf's Ctrl-R binding at the prompt, with native incremental search as the no-fzf fallback; remove the unused multi-word history plugin and forced exact matching in fzf. Keep one private history snapshot per day without overwriting existing snapshots. Move only the live Kiro pre-hook after the history limits are established; preserve other live/source drift.
- **Recovery**: Nine source files were copied with SHA-256 provenance to `~/.local/state/zsh/recovery-20261022-014722/`. Native Zsh history import recovered older commands and then appended the full original current sequence, which was verified unchanged byte-for-byte at the output tail before replacement. Zsh reported 4,851 recovered events. This is partial recovery, not proof of an uninterrupted archive. Existing terminals retain their settings until reloaded.
- **Verification**: `bash tests/zsh_history_check.sh` retains 1,600 events past the system's 1,000-event default and checks immutable daily snapshots. `python3 tests/zsh_completion_ui.py` also checks contextual suggestion ranking and fzf Ctrl-R after Television initialization. Existing completion, syntax, and config checks still apply.
- **Additional recovery (same day)**: Consistent read transactions against the Amazon Q and Kiro SQLite history tables yielded 14,738 additional events after exact timestamp/command deduplication. Private history-only database snapshots, hashes, pre-merge history, the candidate, and coverage metadata live in `~/.local/state/zsh/recovery-databases-20261022-015945/`; authentication tables were not copied. The installed chronological merge has 19,593 events, and native Zsh read-back matched every command without mismatches. A bounded scan of 7,450 yadm blobs (20 KB–1 MB) found no additional extended-history files.
- **Truncation mechanism**: An isolated shell retaining limits of 2,000 in memory / 1,000 saved reduced a 5,000-event replacement file to 1,000 when it exited. With managed env/options it retained 5,001 events instead. This proves the stale-writer mechanism, not attribution to a specific historical PID. The reproduction is now in `tests/zsh_history_check.sh`. The apply guard evaluates the actual sourced history option states, catching the sharing/incremental conflict without mistaking `unsetopt HIST_IGNORE_ALL_DUPS` for enabling it.

### ADR-009: Weekly Zsh History Backups
- **Date**: 2026-10-22
- **Status**: Accepted
- **Decision**: Use the existing macOS LaunchAgent convention for a Sunday 12:00 local-time job (`dev.dotfiles.zsh-history-backup`). Unlike cron, a calendar invocation missed during sleep runs after wake. The plist is managed by chezmoi and excluded on other operating systems.
- **Storage**: `~/.scripts/backup-zsh-history-weekly` writes unique timestamped gzip archives under `~/.backups/zsh-history/`, retaining all copies. The directory is private (0700), archives are 0600, and compression is checked before publishing a finished archive. Empty/missing input fails rather than creating an empty backup. This backs up canonical Zsh history only; the older `backup-zsh-history` command remains the broader recovery-source collector. Logs go to `~/Library/Logs/zsh-history-backup.log`.
- **Verification**: `bash tests/zsh_history_backup_check.sh` checks decompression, separate copies, empty input, private permissions, and staging cleanup. The installed LaunchAgent was bootstrapped and manually triggered; it exited 0, and the first archive decompressed byte-for-byte to the current history. Both managed targets have empty chezmoi status.

### ADR-010: Terminal AI Rewrite Widgets and the `slop` Command
- **Date**: 2026-10-22
- **Status**: Accepted
- **Context**: Text could be sent to an LLM through `plz` (stdin to stdout, Codex or Claude), but there was no way to apply the result to a terminal command line, and no default "strip AI patterns" prompt. `plz` also defaulted to `gpt-5.4-mini`, which the Codex CLI rejects on a ChatGPT account, so its default path failed.
- **Decision**: Add `dot_config/zsh/slop.zsh` with three ZLE widgets: `^X^E` rewrites the current command line with the default de-slop instruction, `^X^I` asks for an instruction first, and a command line prefixed with `ai:` prompts for an instruction on Enter and puts the rewrite back in the buffer for review. Add `dot_scripts/executable_slop` as the same rewrite as a stdin/stdout filter. Change the `plz` default Codex model to `gpt-6-luna`.
- **Implementation notes**:
  - `Ctrl-X Ctrl-S` is XOFF, so the terminal swallows the next keystroke. `^X^E` and `^X^I` are used instead.
  - Reading the instruction must happen in the current shell, not in a command substitution: in a subshell the terminating newline does not end the read and the answer runs into the next input. The value is read into `_SLOP_REPLY` after `zle -I` suspends ZLE.
  - The widget file is sourced from `dot_config/zsh/functions.zsh` because the live `~/.zshrc` has drifted from the source (Kiro blocks, an API key) and is mode 0600; a whole-file apply of `.zshrc` would clobber that drift and loosen the mode.
- **Verification**: Exercised in a pty harness: `^X^E` rewrote a buffered command, `^X^I` prompted and rewrote, the `ai:` prefix prompted and rewrote, an empty instruction preserved the original, and ordinary command execution was unaffected. `zsh -ic` confirmed all three bindings are registered under the live `.zshrc`.
- **Consequences**: The `ai:` prefix reserves that word at the start of a command line. The rewrite is a command-line substitution, so it edits the buffer rather than a file; use `slop` for file or clipboard text.

### ADR-011: Linux Weekly History Backup Scheduling
- **Date**: 2026-10-24
- **Status**: Accepted
- **Context**: ADR-009 deployed only a macOS scheduler even though the shared backup script supports Linux.
- **Decision**: Add Linux-only systemd user service/timer units for Sunday noon, with `Persistent=true` to catch up after downtime. Keep the macOS LaunchAgent unchanged. Document explicit one-time activation rather than starting jobs during chezmoi apply; non-systemd Linux hosts can schedule the same script themselves.
- **Consequences**: No root service or new dependency; the user manager must run for backups to execute. Lingering is optional and requires an explicit administrative choice. Regression checks cover the schedule, script wiring, and chezmoi platform selection. The manual activation policy above was superseded by ADR-012.

### ADR-012: Activate Linux History Backups During Chezmoi Apply
- **Date**: 2026-10-24
- **Status**: Accepted
- **Context**: Requiring separate systemctl commands after deploying the units makes Linux setup easy to leave unfinished.
- **Decision**: A Linux-only `run_after_` template reloads the user manager and enables/starts the timer after a full apply. Run on every apply, not once/onchange, so a skipped activation is retried when a user manager becomes available. Skip only missing systemctl/unreachable user managers; propagate reload/enable failures.
- **Consequences**: Full applies now enforce timer activation; disabling it manually is undone by the next full apply. macOS activation and optional Linux lingering remain unchanged. Scoped file-only applies do not activate the timer. Mocked systemctl tests check after-script ordering, retries, platform gating, and error propagation without starting local jobs.

### ADR-013: Safe Runtime Hooks and Isolated Completion Fixtures
- **Date**: 2026-10-24
- **Status**: Accepted
- **Context**: The Ruby postinstall hook called an unsupported mise command and returned failure for non-Ruby installs. Completion tests could inherit real history, cache, and startup paths.
- **Decision**: Use a POSIX conditional with `mise install --force gem:colorls`; non-Ruby installs succeed without doing work, while rebuild failures propagate. Default completion tests isolate HOME/XDG/ZDOTDIR before starting Zsh. The UI fixture copies the installed standalone autosuggestions script and sources checkout configuration, without plugin downloads or personal bundle loading.
- **Consequences**: Stubbed runtime tests never install tools. UI tests require installed dependencies and accept `ZSH_AUTOSUGGESTIONS_FILE` for nonstandard plugin locations. The registration test's explicit `--live` mode remains intentionally non-isolated.

### ADR-014: Native Ctrl-R History Search
- **Date**: 2026-10-25
- **Status**: Accepted
- **Context**: The user requested disabling the fuzzy history picker. At the normal prompt fzf owned Ctrl-R, with `--no-sort` disabling relevance ranking; Television also assigned the key during startup.
- **Decision**: Supersede ADR-008's fzf binding with native `history-incremental-search-backward`, reasserted by the existing prompt hook after integrations. Leave fzf and Television installed for their other features. Persist the live fix with a scoped chezmoi re-add and apply.
- **Verification**: Update the isolated ZLE UI regression to check newest-to-oldest native matching and cancellation after late Television initialization.
- **Consequences**: Ctrl-R searches literal history matches backward instead of opening a fuzzy picker. Existing shells need a new tab or a reload of the managed completion file.

### ADR-015: Configurable Pi Footer with Joined Model and Effort
- **Date**: 2026-10-25
- **Status**: Accepted
- **Context**: The user requested removing Last tok/s, Cost, Today, Input, and Output and displaying `model-id:effort` with a level-specific effort color. The previous `@reedchan/statusline` package did not expose these controls. The user approved replacing it and dropping TTFT, averages, and the context-breakdown panel.
- **Decision**: Use reviewed, pinned `@sentixx/pi-info@0.8.0` in footer-only mode, preserving `pi-pretty-tui`'s editor. Configure path, lavender branch, cyan model, theme-semantic effort colors, threshold-colored context, cache hit, and extension statuses in `dot_pi/agent/pi-info.json.tmpl`. The supported custom renderer joins the preformatted model and thinking parts without a separator and uses Pi's public width truncation helper; no installed package/core files are patched.
- **Chezmoi**: `dot_pi/agent/modify_settings.json` owns only the footer package declaration and preserves all unrelated runtime settings/packages. It handles an empty first-run settings file, rejects malformed JSON, and drops obsolete old-package resource filters during migration. Apply the settings modifier, JSON config, and renderer as three scoped targets. Edit the source JSON template for future visibility/order/format/color changes; the renderer remains outside extension discovery.
- **Worktrees**: pi-info's built-in branch reader does not handle linked worktrees. Override the branch using its supported command-segment config with `git symbolic-ref --quiet --short HEAD`, cached for five seconds. No package patch or extra extension is needed; the regression fixture uses a real linked worktree.
- **Verification**: `python3 tests/pi_statusline_ui.py` runs installed Pi 1.4.0 with copied packages, temporary HOME/XDG/agent-dir, an isolated tmux socket, synthetic provider, `--offline`, no saved session, and an OS sandbox denying networking and writes outside its temporary tree. It checks modifier preservation/idempotence, empty initialization, obsolete-filter migration, malformed-input rejection, removed fields, `model:high`/`:xhigh`, distinct semantic effort colors, linked-worktree path/branch/extensions, existing TUI packages, reload, resize, and clean exit without model calls. Installed package bytes match the reviewed tarball; scoped chezmoi status/diff are empty.
- **Activation**: Restart the running Pi session to discover the replacement package reliably. Once loaded, the package watches config changes; reload behavior is covered by the isolated test.
- **Rollback**: The original settings snapshot for this change is `/tmp/pi-statusline-before.nDnupi/settings.json` (temporary, not a long-term backup). To revert without overwriting later settings changes, reverse the package mapping in the chezmoi modifier to target `npm:@reedchan/statusline@1.11.3`, apply only the settings target, and ensure that package is installed. Restart Pi. The new JSON/renderer are inert when pi-info is not loaded.
- **Install warning**: npm reported an existing high-severity `zod@4.4.3` advisory through `pi-extension-manager@0.8.2`, not through pi-info (which has no runtime dependencies). No audit fixes or unrelated updates were applied.

### ADR-016: Observe Recurring Zsh History Loss
- **Date**: 2026-10-28
- **Status**: Reverted; polling agent stopped and disabled after user requested causal attribution instead of mitigation.
- **Context**: The October 22 weekly archive still contains the recovered 19,593 events with its original checksum, while the October 25 archive has 690 and the current file has 1,048. The stale-shell truncation reproduction from ADR-008 establishes a mechanism, not attribution to a historical process.
- **Decision**: Run a macOS user LaunchAgent checking canonical history once per second. Keep the last observed copy and preserve before/after files on non-append changes or deletion, plus UTC time, sizes, and running Zsh process metadata. Keep all evidence private under `~/.backups/zsh-history-watch/`; logs contain only sizes and paths. Do not automatically restore history or interfere with shells.
- **Limits**: Polling can miss intermediate writes. Process lists are candidates, not writer attribution; macOS `fs_usage` needs administrator access, unavailable noninteractively in this session. Normal history compaction may also produce a captured rewrite. Weekly archives remain independent. Unload the agent with `launchctl bootout "gui/$(id -u)/dev.dotfiles.zsh-history-watch"`.
- **Verification**: Disposable fixtures pass for append, atomic replacement/truncation, deletion, equal-size rewrite, empty input, and private permissions. An isolated running process captures a truncation and rejects a second instance. Live LaunchAgent is running; its initial snapshot matches canonical history byte-for-byte, directory/files are 0700/0600, and scoped chezmoi status is empty. Existing history-retention and weekly-backup checks also pass. Mise emits an existing cache-permission warning without preventing startup.
- **Correction**: The running state above describes initial deployment only. The agent is now unloaded and persistently disabled; its evidence remains intact. Snapshot comparison establishes another loss between the October 24 and 25 daily snapshots (234 leading events removed), followed by append-only growth through today. Generic stale-writer tests do not attribute either loss. A manually invoked native `eslogger` trace is prepared under `~/.local/state/zsh/diagnosis-20261028/`; administrator authentication is required before it can run.
- **Repository ownership**: Keep the rejected watch implementation local and excluded from Git and chezmoi deployment. Preserve existing evidence; do not restart the watch.

### ADR-017: Keep Dynamic Aliases in One Runtime-Owned File

- **Date**: 2026-10-28
- **Context**: `addalias` appended to the static `aliases.zsh`, while `lsa` required a section marker that `addalias` never created. Chezmoi could overwrite aliases added to the live static file.
- **Decision**: `addalias` and `lsa` share `user-aliases.zsh` under the Zsh config directory. Static aliases load it at startup. Chezmoi's `create_private_` seed creates the file once with mode 0600 and leaves runtime additions intact on later applies. The file is machine-local; normal reconciliation must not re-add it over the seed. Minor direct edits are supported.
- **Behavior**: Validate names, reject alias/function collisions, preserve descriptions, quote commands with native Zsh ANSI-C quoting, and activate only the new alias after a successful append. Do not source the whole static config after an addition.
- **Migration**: Move the existing live user alias `ghq='githubq'` and its description out of the legacy static section. Preserve unrelated live/source differences.
- **Verification**: `mise exec -- python tests/zsh_alias_check.py` checks fresh-shell loading, descriptions, quote/newline round-trips, collisions, invalid input, canceled reads, failed writes, and real create-only chezmoi apply preserving runtime additions.

### ADR-018: Reconcile Pending Changes After the VPS Rebase

- **Date**: 2026-10-28
- **Status**: Accepted
- **Context**: Local commits and uncommitted shell, backup, runtime and Pi changes needed reconciliation with the VPS commit. Both branches had assigned ADR-006 independently.
- **Decision**: Preserve both histories and decisions; identify the VPS decision as ADR-006a. Keep shared mise versions aligned with the already installed versions, retain the corrected Ruby postinstall hook, and keep machine-only tools in untracked `~/.config/mise/conf.d/host.toml`. Exclude local agent settings, bytecode and the rejected polling watch from deployment.
- **Completion**: Bind menu Escape to Zsh's native `send-break`. The previous widget cleared the display while leaving menu selection active, so the next Ctrl-U accepted a match instead of clearing the input. The isolated UI regression reproduces the failure and verifies real cancellation, fresh files, flags and native history search.
- **FIGlet**: Keep the existing `fig` font/animation helpers and aliases. Stubbed binaries verify font selection, arguments, stdin and pipeline failure without terminal animation.
- **Verification repair**: Use Git's tracked/nonignored file list for secret-scan staging, compatible with macOS Bash 3.2. Run hk as a child so staging cleanup executes on success and failure; isolated regressions and the real staged secret scan pass. This resolves `dotfiles-pkh`.
- **Limits**: This reconciliation does not resolve the historical history writer or the other eight audit findings. No services are enabled or packages installed.
