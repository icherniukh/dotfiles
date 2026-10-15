# Shared by statusline-mobile.sh and statusline-desktop.sh (sourced, not run):
# reads the statusLine JSON from stdin, defines the palette and helpers.

input=$(cat)

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
MUTED='140;146;158'    # separators, time-left
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

# Current branch, or short SHA when detached; empty outside a repo.
git_branch() {
  local b
  b=$(git --no-optional-locks -C "$1" branch --show-current 2>/dev/null || true)
  [[ -z "$b" ]] && b=$(git --no-optional-locks -C "$1" rev-parse --short HEAD 2>/dev/null || true)
  printf '%s' "$b"
}

# "opus5.5:high" — model family hue, effort on the calm -> hot ramp.
model_segment() {
  local compact seg
  compact=$(sed -E 's/^[Cc]laude[[:space:]]+//' <<<"$model_display" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
  seg="$(fg "$(model_color "$model_display")")${compact}${RESET}"
  [[ -n "$effort" ]] && seg+="$(fg "$MUTED"):${RESET}$(fg "$(effort_color "$effort")")${effort/medium/med}${RESET}"
  printf '%s' "$seg"
}

# Prints the given segments joined by a muted "│".
join_segments() {
  local sep out="" i=0 s
  sep="$(fg "$MUTED")│${RESET}"
  for s in "$@"; do
    (( i++ > 0 )) && out+="$sep"
    out+="$s"
  done
  printf '%s' "$out"
}
