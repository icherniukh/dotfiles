#!/usr/bin/env bash
# Claude Code statusLine entry point: phone (Moshi) sessions get the compact
# mobile line, everything else the desktop one. Checked on every refresh, so a
# tmux session re-attached from the phone switches over.
set -euo pipefail

dir="$(dirname "${BASH_SOURCE[0]}")"

# Moshi exports MOSHI_CLIENT=1; inside tmux it reaches the session env via update-environment.
is_moshi() {
  [[ "${MOSHI_CLIENT:-}" == 1 ]] && return 0
  [[ -n "${TMUX:-}" ]] && [[ "$(tmux show-environment MOSHI_CLIENT 2>/dev/null)" == "MOSHI_CLIENT=1" ]]
}

if is_moshi; then
  exec "$dir/statusline-mobile.sh"
else
  exec "$dir/statusline-desktop.sh"
fi
