#!/usr/bin/env bash
# Claude Code statusLine — plain background, real progress bars, compact.
set -euo pipefail

input=$(cat)

# Labels ("5h", "wk", "ctx") are hidden by default. Show them by setting
# CC_STATUSLINE_LABELS=1 in the statusLine command (settings.json) or shell env.
show_labels="${CC_STATUSLINE_LABELS:-0}"

cwd=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
model_display=$(jq -r '.model.display_name // .model.id // "model"' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
ctx_pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
fh_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
fh_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
wk_pct=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
wk_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$input")

CYAN='0;225;255'       # path — vivid cyan
BRANCH='190;140;255'   # git branch — soft violet
MUTED='140;146;158'    # separators, time-left, empty bar
GOOD='40;255;120'      # vivid green
WARN='255;150;20'      # vivid orange
BAD='255;45;85'        # vivid red/crimson

FH_COLOR='255;196;0'    # 5h % — vivid gold
WK_COLOR='48;140;255'   # weekly % — vivid blue

RESET=$'\033[0m'
BOLD=$'\033[1m'
fg() { printf '\033[38;2;%sm' "$1"; }

pct_color() {
  local ipct=${1%%.*}; ipct=${ipct:-0}
  if (( ipct >= 80 )); then printf '%s' "$BAD"
  elif (( ipct >= 50 )); then printf '%s' "$WARN"
  else printf '%s' "$GOOD"
  fi
}

# Model family -> fixed hue, spread across distinct vivid hues.
model_color() {
  local m; m=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  case "$m" in
    *sonnet*) printf '90;140;255'  ;;   # vivid periwinkle-blue
    *opus*)   printf '200;80;255'  ;;   # vivid violet
    *haiku*)  printf '60;235;140'  ;;   # vivid mint-green
    *fable*)  printf '255;70;170'  ;;   # vivid hot pink
    *)        printf '255;196;0'   ;;   # gold fallback
  esac
}

# Effort/reasoning level -> vivid intensity ramp (calm -> hot).
effort_color() {
  local e; e=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  case "$e" in
    low)     printf '0;220;200'   ;;   # vivid teal
    medium)  printf '255;225;0'   ;;   # vivid yellow
    high)    printf '255;120;0'   ;;   # vivid orange
    xhigh)   printf '255;35;120'  ;;   # vivid crimson-pink
    max)     printf '255;0;200'   ;;   # vivid magenta
    *)       printf '%s' "$MUTED" ;;
  esac
}

# Draws an N-char block bar, filled portion colored by threshold, rest muted.
draw_bar() {
  local pct=${1%%.*} width=$2 filled empty i bar_filled bar_empty
  pct=${pct:-0}; (( pct > 100 )) && pct=100; (( pct < 0 )) && pct=0
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar_filled=""; for ((i=0;i<filled;i++)); do bar_filled+="█"; done
  bar_empty=""; for ((i=0;i<empty;i++)); do bar_empty+="░"; done
  printf '%s%s%s%s' "$(fg "$(pct_color "$pct")")" "$bar_filled" "$(fg "$MUTED")" "$bar_empty"
}

fmt_left() {
  local reset_epoch="$1"
  [[ -z "$reset_epoch" || "$reset_epoch" == "null" ]] && return
  local now diff d h m
  now=$(date +%s)
  diff=$(( ${reset_epoch%%.*} - now ))
  (( diff < 0 )) && diff=0
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if (( d > 0 )); then printf '%dd%dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"
  fi
}

# Moshi (phone) exports MOSHI_CLIENT=1; inside tmux it reaches the session env via update-environment.
is_moshi() {
  [[ "${MOSHI_CLIENT:-}" == 1 ]] && return 0
  [[ -n "${TMUX:-}" ]] && [[ "$(tmux show-environment MOSHI_CLIENT 2>/dev/null)" == "MOSHI_CLIENT=1" ]]
}

pad_pct() { printf '%d' "${1%%.*}"; }  # no padding: narrow phone screens

abbrev_path() {
  local p="$1"
  if [[ "$p" == "$HOME" ]]; then printf '~'; return; fi
  [[ "$p" == "$HOME"/* ]] && p="~${p#"$HOME"}"
  IFS='/' read -ra parts <<<"$p"
  local n=${#parts[@]} out="" i seg
  for i in "${!parts[@]}"; do
    seg="${parts[$i]}"
    [[ -z "$seg" ]] && continue
    if (( i == n - 1 )); then
      out+="/${seg}"
    elif [[ "$seg" == "~" ]]; then
      out+="${seg}"
    else
      out+="/${seg:0:1}"
    fi
  done
  printf '%s' "${out:-/}"
}

segments=()

if [[ -n "$cwd" ]]; then
  seg="$(fg "$CYAN")$(abbrev_path "$cwd")${RESET}"
  branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null || true)
  [[ -z "$branch" ]] && branch=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
  [[ -n "$branch" ]] && seg+="$(fg "$MUTED"):${RESET}$(fg "$BRANCH")${branch}${RESET}"
  segments+=("$seg")
fi

if [[ -n "$ctx_pct" ]]; then
  label=""; [[ "$show_labels" != "0" ]] && label="$(fg "$MUTED")ctx ${RESET}"
  bar=""; is_moshi || bar="$(draw_bar "$ctx_pct" 5)${RESET}"
  segments+=("${label}${bar}$(fg "$(pct_color "$ctx_pct")")${BOLD}$(pad_pct "$ctx_pct")%${RESET}")
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

model_compact=$(sed -E 's/^[Cc]laude[[:space:]]+//' <<<"$model_display" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
model_seg="$(fg "$(model_color "$model_display")")${model_compact}${RESET}"
[[ -n "$effort" ]] && model_seg+="$(fg "$MUTED"):${RESET}$(fg "$(effort_color "$effort")")${effort/medium/med}${RESET}"
segments+=("$model_seg")

sep="$(fg "$MUTED")│${RESET}"
out=""
for i in "${!segments[@]}"; do
  (( i > 0 )) && out+="$sep"
  out+="${segments[$i]}"
done

printf '%s' "$out"
