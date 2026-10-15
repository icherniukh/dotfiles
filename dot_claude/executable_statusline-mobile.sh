#!/usr/bin/env bash
# Claude Code statusLine for phone (Moshi) sessions — plain background, compact.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/statusline-lib.sh"

# Labels ("5h", "wk", "ctx") are hidden by default. Show them by setting
# CC_STATUSLINE_LABELS=1 in the statusLine command (settings.json) or shell env.
show_labels="${CC_STATUSLINE_LABELS:-0}"

pad_pct() { printf '%d' "${1%%.*}"; }  # no padding: narrow phone screens

segments=()

if [[ -n "$cwd" ]]; then
  seg="$(fg "$CYAN")$(abbrev_path "$cwd")${RESET}"
  branch=$(git_branch "$cwd")
  [[ -n "$branch" ]] && seg+="$(fg "$MUTED"):${RESET}$(fg "$BRANCH")${branch}${RESET}"
  segments+=("$seg")
fi

if [[ -n "$ctx_pct" ]]; then
  label=""; [[ "$show_labels" != "0" ]] && label="$(fg "$MUTED")ctx ${RESET}"
  segments+=("${label}$(fg "$(pct_color "$ctx_pct")")${BOLD}$(pad_pct "$ctx_pct")%${RESET}")
fi

if [[ -n "$fh_pct" ]]; then
  left=$(fmt_left "$fh_reset")
  label=""; [[ "$show_labels" != "0" ]] && label="$(fg "$MUTED")5h ${RESET}"
  seg="${label}$(fg "$FH_COLOR")${BOLD}$(pad_pct "$fh_pct")%${RESET}"
  [[ -n "$left" ]] && seg+="$(fg "$MUTED")·${left}${RESET}"
  segments+=("$seg")
fi

if [[ -n "$wk_pct" ]]; then
  left=$(fmt_left "$wk_reset")
  label=""; [[ "$show_labels" != "0" ]] && label="$(fg "$MUTED")wk ${RESET}"
  seg="${label}$(fg "$WK_COLOR")${BOLD}$(pad_pct "$wk_pct")%${RESET}"
  [[ -n "$left" ]] && seg+="$(fg "$MUTED")·${left}${RESET}"
  segments+=("$seg")
fi

segments+=("$(model_segment)")

join_segments "${segments[@]}"
