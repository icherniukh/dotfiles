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
