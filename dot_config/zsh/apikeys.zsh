# Tracked, non-secret API key wiring.
#
# Never put real secrets in this file (it will be committed).
# Put real values in `~/.config/zsh/secrets.zsh` (ignored) or in your OS keychain/env.
#
# Example patterns (set the actual values in `secrets.zsh`):
#   export OPENAI_API_KEY="..."          # OpenAI
#   export ANTHROPIC_API_KEY="..."       # Anthropic
#   export GITHUB_TOKEN="..."            # GitHub
#
# This file can normalize variable names or set non-sensitive defaults.

# If you use multiple key names across tools, normalize them here (no literals).
[[ -n ${OPENAI_API_KEY-} ]] && export OPENAI_API_KEY
[[ -n ${ANTHROPIC_API_KEY-} ]] && export ANTHROPIC_API_KEY
[[ -n ${GITHUB_TOKEN-} ]] && export GITHUB_TOKEN

