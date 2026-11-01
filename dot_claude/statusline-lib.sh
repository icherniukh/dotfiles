# Shared by statusline-mobile.sh and statusline-desktop.sh (sourced, not run):
# reads the statusLine JSON from stdin, defines the palette and helpers.

input=$(cat)

# One jq call: the statusline re-runs every second (refreshInterval). \x1f keeps empty fields.
IFS=$'\x1f' read -r cwd model_display effort ctx_pct ctx_tok ctx_size fh_pct fh_reset wk_pct wk_reset < <(
  jq -r '[(.workspace.current_dir // .cwd // ""), (.model.display_name // .model.id // "model"),
    (.effort.level // ""), (.context_window.used_percentage // ""),
    ((.context_window.current_usage // null) | if . then (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) else "" end),
    (.context_window.context_window_size // ""),
    (.rate_limits.five_hour.used_percentage // ""), (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""), (.rate_limits.seven_day.resets_at // "")]
    | map(tostring) | join("\u001f")' <<<"$input")
[[ -z "$ctx_tok" && -n "$ctx_pct" && -n "$ctx_size" ]] && ctx_tok=$(( ${ctx_pct%%.*} * ctx_size / 100 ))
ctx_tok=${ctx_tok:-0}

CYAN='0;225;255'       # path — vivid cyan
BRANCH='190;140;255'   # git branch — soft violet
MUTED='140;146;158'    # separators, time-left
GOOD='40;255;120'      # vivid green
WARN='255;150;20'      # vivid orange
BAD='255;45;85'        # vivid red/crimson
PLUM='221;160;221'     # context % and token count
TRACK='58;62;72'       # empty part of the context bar

FH_COLOR='255;196;0'    # 5h % — vivid gold
WK_COLOR='48;140;255'   # weekly % — vivid blue

RESET=$'\033[0m'
BOLD=$'\033[1m'
fg() { printf '\033[38;2;%sm' "$1"; }

# lerp A B X0 X1 X -> integer A..B as X goes X0..X1
lerp() { echo $(( $1 + ($2 - $1) * ($5 - $3) / ($4 - $3) )); }

# Context tokens -> RGB: green until 75k, lime, yellow, orange at 175k, red at 250k.
CTX_T=(0 75000 108000 142000 175000 250000)
CTX_C=("$GOOD" "$GOOD" '170;255;0' '255;225;0' "$WARN" "$BAD")
ctx_color() {
  local t=$1 i a b
  (( t >= CTX_T[-1] )) && { printf '%s' "${CTX_C[-1]}"; return; }
  for ((i=1; i<${#CTX_T[@]}; i++)); do
    (( t < CTX_T[i] )) || continue
    IFS=';' read -ra a <<<"${CTX_C[i-1]}"; IFS=';' read -ra b <<<"${CTX_C[i]}"
    printf '%d;%d;%d' "$(lerp "${a[0]}" "${b[0]}" "${CTX_T[i-1]}" "${CTX_T[i]}" "$t")" \
      "$(lerp "${a[1]}" "${b[1]}" "${CTX_T[i-1]}" "${CTX_T[i]}" "$t")" \
      "$(lerp "${a[2]}" "${b[2]}" "${CTX_T[i-1]}" "${CTX_T[i]}" "$t")"
    return
  done
}

# Pulse period in seconds (0 = none): 250k 20s -> 265k 10s -> 400k 4s -> 500k+ 2s.
ctx_period() {
  local t=$1
  if   (( t < 250000 )); then echo 0
  elif (( t < 265000 )); then lerp 20 10 250000 265000 "$t"
  elif (( t < 400000 )); then lerp 10 4 265000 400000 "$t"
  elif (( t < 500000 )); then lerp 4 2 400000 500000 "$t"
  else echo 2
  fi
}

# WIDTH-char bar for VALUE/MAX at 1/8-cell resolution, filled in COLOR on a solid TRACK.
# The partial cell gets a TRACK background so there's no gap; BG_RESTORE resets it after.
PARTIAL=('' ▏ ▎ ▍ ▌ ▋ ▊ ▉)
ctx_bar() {
  local val=$1 max=$2 width=$3 color=$4 bg_restore=${5:-$'\033[49m'} eighths full i out=""
  eighths=$(( val * width * 8 / max )); (( eighths > width * 8 )) && eighths=$(( width * 8 ))
  full=$(( eighths / 8 ))
  for ((i=0;i<full;i++)); do out+="█"; done
  (( eighths % 8 )) && out+=$'\033[48;2;'"${TRACK}m${PARTIAL[eighths % 8]}${bg_restore}"
  printf '%s%s%s' "$(fg "$color")" "$out" "$(fg "$TRACK")"
  for ((i=full + (eighths % 8 > 0); i<width; i++)); do printf '█'; done
}

# "<bar> 8%·82k". Bar color ramps with tokens and is scaled to 500k (where the alarm tops out),
# or the window if smaller; past 250k the segment pulses, faster and harder as tokens grow.
# Optional WIDTH (default 0 = no bar, for the phone).
ctx_segment() {
  local width=${1:-0} color pre="" period phase flash bar="" bar_max=500000 pct_fg r g b
  color=$(ctx_color "$ctx_tok") period=$(ctx_period "$ctx_tok")
  if (( period > 0 )); then
    phase=$(( EPOCHSECONDS % period ))
    IFS=';' read -r r g b <<<"$color"
    flash="$(( (r+255*3)/4 ));$(( (g+255*3)/4 ));$(( (b+255*3)/4 ))"
    if (( ctx_tok >= 400000 && phase == 0 )); then
      pre=$'\033[48;2;'"${color}m" color='255;255;255'   # intense: solid red block
    elif (( phase == 0 || (ctx_tok >= 400000 && period > 2 && phase == 1) )); then
      color=$flash                                         # mild flash / intense afterglow
    fi
  fi
  (( ${ctx_size:-0} > 0 && ctx_size < bar_max )) && bar_max=$ctx_size
  pct_fg=$PLUM; [[ -n "$pre" ]] && pct_fg=$color
  (( width > 0 )) && bar="$(ctx_bar "$ctx_tok" "$bar_max" "$width" "$color" "$pre") "
  printf '%s' "${pre}${bar}$(fg "$pct_fg")${BOLD}$(printf '%d' "${ctx_pct%%.*}")%${RESET}${pre}$(fg "$MUTED")·$(fg "$pct_fg")$(( (ctx_tok + 500) / 1000 ))k${RESET}"
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
