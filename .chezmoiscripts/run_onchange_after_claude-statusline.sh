#!/usr/bin/env bash
# Point Claude Code's statusLine at the chezmoi-managed ~/.claude/statusline.sh.
# settings.json is edited in place (not managed) because Claude Code rewrites it;
# only the statusLine key is touched. Re-runs whenever this script changes.
# refreshInterval 1 re-renders every second so the context pulse can animate.
set -euo pipefail

settings="$HOME/.claude/settings.json"
command='~/.claude/statusline.sh'

if ! command -v jq >/dev/null 2>&1; then
  echo "claude-statusline: jq not found, skipping statusLine setup" >&2
  exit 0
fi

mkdir -p "$(dirname "$settings")"
[[ -s "$settings" ]] || echo '{}' >"$settings"

want=$(jq -nc --arg cmd "$command" '{type: "command", command: $cmd, refreshInterval: 1}')
jq -e --argjson want "$want" '.statusLine == $want' "$settings" >/dev/null && exit 0

tmp=$(mktemp "$settings.XXXXXX")
trap 'rm -f "$tmp"' EXIT
jq --argjson want "$want" '.statusLine = $want' "$settings" >"$tmp"
cp "$settings" "$settings.pre-statusline.bak"
mv "$tmp" "$settings"
trap - EXIT
echo "claude-statusline: statusLine -> $command"
