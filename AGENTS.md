# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work atomically
bd close <id>         # Complete work
bd dolt push          # Push beads data to remote
```

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.

Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.

**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file

# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```

**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

## Chezmoi Workflow

- This repo is the chezmoi source. Edit files here, then `chezmoi apply <target>`, scoped to the paths you touched.
- If a live file changed directly (by hand or by a tool), run `chezmoi re-add <target>` (or `chezmoi add` for new files) before the next apply, or the apply will revert it.
- `chezmoi status <target>` must be empty before calling a change done. Check `chezmoi diff` first and report unrelated drift instead of absorbing or overwriting it.
- Yazi plugins/flavors are managed by `ya pkg`. After `ya pkg install/upgrade`, run `chezmoi add ~/.config/yazi/package.toml ~/.config/yazi/plugins/<name>.yazi` (see ADR-003).
- Log notable config decisions and reversions in `DECISIONS.md`.
