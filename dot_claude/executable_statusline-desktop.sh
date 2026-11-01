#!/usr/bin/env bash
# Claude Code statusLine for desktop sessions — same palette as the phone line,
# plus usage bars and a dirty-tree marker, since width isn't tight here.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/statusline-lib.sh"

BAR_WIDTH=8

# The 5h and weekly sections run warm -> cool as their horizon widens. Context has its own
# token-driven ramp and pulse (ctx_segment in statusline-lib.sh).
FH_HUE='238;200;95'     # 5h limit — wheat gold
WK_HUE='135;205;150'    # weekly limit — sage

# Same hue at ~55% brightness, for the reset countdown.
dim() {
  local r g b
  IFS=';' read -r r g b <<<"$1"
  printf '%d;%d;%d' $(( r * 55 / 100 )) $(( g * 55 / 100 )) $(( b * 55 / 100 ))
}

# N-char block bar, filled part in the section's own hue, rest muted.
draw_bar() {
  local hue=$1 pct=${2%%.*} filled i bar=""
  pct=${pct:-0}; (( pct > 100 )) && pct=100; (( pct < 0 )) && pct=0
  filled=$(( (pct * BAR_WIDTH + 50) / 100 ))
  for ((i = 0; i < BAR_WIDTH; i++)); do
    (( i == filled )) && bar+="$(fg "$MUTED")"
    (( i < filled )) && bar+="█" || bar+="░"
  done
  printf '%s%s%s' "$(fg "$hue")" "$bar" "$RESET"
}

# "<bar> <pct>%  <time left>" — bar/pct in the section's fixed hue, time left in its dimmed hue.
usage_segment() {
  local hue=$1 pct=$2 reset=$3 seg left
  seg="$(draw_bar "$hue" "$pct") $(fg "$hue")${BOLD}$(printf '%d' "${pct%%.*}")%${RESET}"
  left=$(fmt_left "$reset")
  [[ -n "$left" ]] && seg+="  $(fg "$(dim "$hue")")${left}${RESET}"
  printf '%s' "$seg"
}

# Desktop has room: pad the shared "│" border with a space on each side.
join_spaced() {
  local sep out="" i=0 s
  sep=" $(fg "$MUTED")│${RESET} "
  for s in "$@"; do
    (( i++ > 0 )) && out+="$sep"
    out+="$s"
  done
  printf '%s' "$out"
}

segments=()

if [[ -n "$cwd" ]]; then
  seg="$(fg "$CYAN")$(abbrev_path "$cwd")${RESET}"
  branch=$(git_branch "$cwd")
  if [[ -n "$branch" ]]; then
    seg+="$(fg "$MUTED"):${RESET}$(fg "$BRANCH")${branch}${RESET}"
    [[ -n "$(git --no-optional-locks -C "$cwd" status --porcelain -uno 2>/dev/null | head -1)" ]] \
      && seg+="$(fg "$WARN")*${RESET}"
  fi
  segments+=("$seg")
fi

[[ -n "$ctx_pct" ]] && segments+=("$(ctx_segment "$BAR_WIDTH")")
[[ -n "$fh_pct" ]] && segments+=("$(usage_segment "$FH_HUE" "$fh_pct" "$fh_reset")")
[[ -n "$wk_pct" ]] && segments+=("$(usage_segment "$WK_HUE" "$wk_pct" "$wk_reset")")

segments+=("$(model_segment)")

join_spaced "${segments[@]}"
