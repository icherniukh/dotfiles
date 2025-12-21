# Security checklist

- Never commit real secrets (tokens, API keys, private keys).
- Keep secrets in local-only files (example: `~/.config/zsh/secrets.zsh`) and store templates in-repo (`secrets.example.zsh`).
- Keep `~/.ssh/` out of git entirely.
- Before pushing, scan changes:
  - `rg -n \"(BEGIN .* PRIVATE KEY|ghp_|github_pat_|xox[pbar]-|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,})\" -S .`
- If a secret ever hits git history: rotate it, then rewrite history (and force-push) as needed.

