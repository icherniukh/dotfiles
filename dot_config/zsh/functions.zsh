#!/usr/bin/env zsh

[[ -f "$HOME/.config/wezaliases.zsh" ]] && source "$HOME/.config/wezaliases.zsh"

function cf() {
	clifm "--cd-on-quit" "$@"
	dir="$(grep "^\*" "${XDG_CONFIG_HOME:=${HOME}/.config}/clifm/.last" 2>/dev/null | cut -d':' -f2)";
	if [ -d "$dir" ]; then
		cd -- "$dir" || return 1
	fi
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}

# Dynamic aliases live outside the static config; chezmoi only creates this file.
addalias() {
    emulate -L zsh
    if (( $# != 2 )); then
        print -u2 -- "Usage: addalias <alias_name> '<command>'"
        return 1
    fi

    local alias_name="$1" alias_command="$2" description
    local alias_file="${ZSH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/user-aliases.zsh"
    if [[ ! $alias_name =~ '^[A-Za-z_][A-Za-z0-9_-]*$' ]]; then
        print -u2 -- "Error: Invalid alias name '${alias_name}'."
        return 1
    fi
    if (( ${+aliases[$alias_name]} || ${+galiases[$alias_name]} || ${+saliases[$alias_name]} || ${+functions[$alias_name]} )) ||
        { [[ -f $alias_file ]] && command grep -q "^alias ${alias_name}=" "$alias_file"; }; then
        print -u2 -- "Error: Alias or function '${alias_name}' already exists."
        return 1
    fi

    read -r "description?Enter a description for alias '${alias_name}': " || return 1
    command mkdir -p -- "${alias_file:h}" || return 1
    # shortcut: simultaneous same-name additions can race; add locking if used concurrently.
    # ANSI-C quoting keeps commands (including newlines) on one physical line.
    (umask 077; printf '\n# %s\nalias %s=%s\n' "$description" "$alias_name" "${(qqqq)alias_command}" >> "$alias_file") || return 1
    builtin alias -- "${alias_name}=${alias_command}"
    print -r -- "Successfully added alias '${alias_name}'."
}

lsa() {
    emulate -L zsh
    local alias_file="${ZSH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/user-aliases.zsh"
    print -r -- "Custom Aliases (${alias_file})"
    [[ -f $alias_file ]] || return 0
    command awk '
      /^# / { comment = substr($0, 3); next }
      /^alias / {
        name = $0
        sub(/^alias /, "", name)
        sub(/=.*/, "", name)
        printf "%-25s - %s\n", name, (comment == "" ? "-" : comment)
        comment = ""
      }
    ' "$alias_file"
}

brew-ll() {
  brew_installed
}

brew_installed() {
  emulate -L zsh
  unsetopt xtrace 2>/dev/null || true
  set +x 2>/dev/null || true

  if ! command -v brew >/dev/null 2>&1; then
    echo "brew not found" >&2
    return 127
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found (try: brew install jq)" >&2
    return 127
  fi

  local show_analytics=0
  local fetch_missing_analytics=0
  if [[ "${1-}" == "--analytics" ]]; then
    show_analytics=1
    shift
  fi
  if [[ "${1-}" == "--fetch" ]]; then
    fetch_missing_analytics=1
    shift
  fi

  local limit=0
  if [[ "${1-}" == "--limit" ]]; then
    limit="${2-0}"
    shift 2 || true
  fi

  local info_json
  info_json="$(brew info --json=v2 --installed)"

  local use_color=0
  [[ -t 1 ]] && use_color=1

  local cask_color=$'\e[1;36m'    # bold cyan
  local formula_color=$'\e[1;32m' # bold green
  local reset=$'\e[0m'

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/brew-installed"
  local cache_ttl_seconds=$((7 * 24 * 60 * 60)) # 7 days
  local field_sep=$'\x1f'

  _brew_installed_stats() {
    unsetopt xtrace 2>/dev/null || true
    set +x 2>/dev/null || true

    local kind="$1" name="$2"
    local safe="${name//\//__}"
    local cache_file="$cache_dir/${kind}-${safe}.txt"

    if [[ -f "$cache_file" ]]; then
      local now mtime age
      now="$(date +%s)"
      if mtime="$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)"; then
        age=$((now - mtime))
        if (( age < cache_ttl_seconds )); then
          command cat -- "$cache_file"
          return 0
        fi
      fi
    fi

    # Cache-only mode: show nothing unless we already have it.
    if (( fetch_missing_analytics == 0 )); then
      return 0
    fi

    mkdir -p -- "$cache_dir" 2>/dev/null || true

    # Only core formulae/casks are available via formulae.brew.sh API. If this is a tap item,
    # keep stats unknown.
    if [[ "$name" == */* ]]; then
      print -r -- "-/-/-" | tee "$cache_file" >/dev/null 2>&1 || true
      return 0
    fi

    local url
    if [[ "$kind" == "formula" ]]; then
      url="https://formulae.brew.sh/api/formula/${name}.json"
    else
      url="https://formulae.brew.sh/api/cask/${name}.json"
    fi

    local result
    result="$(
      curl -fsSL --max-time 10 "$url" 2>/dev/null \
        | jq -r '
            (.analytics? // {}) as $an
            | (if $kind == "formula"
               then ($an.install_on_request? // $an.install? // {})
               else ($an.install? // {})
               end) as $a
            | (($a["30d"][$pkg] // "-")|tostring) as $d30
            | (($a["90d"][$pkg] // "-")|tostring) as $d90
            | (($a["365d"][$pkg] // "-")|tostring) as $d365
            | "\($d30)/\($d90)/\($d365)"
          ' --arg kind "$kind" --arg pkg "$name" 2>/dev/null
    )" || true

    if [[ -z "${result:-}" ]]; then
      result="-/-/-"
    fi

    print -r -- "$result" | tee "$cache_file" >/dev/null 2>&1 || true
    print -r -- "$result"
  }

  local -a rows
  local max_name=0
  local max_stats=0

  local processed=0
  while IFS=$'\t' read -r type name desc; do
    if (( limit > 0 )) && (( processed >= limit )); then
      break
    fi
    local pkg_stats=""
    if (( show_analytics )); then
      if [[ "$type" == "0" ]]; then
        pkg_stats="$(_brew_installed_stats formula "$name")"
      else
        pkg_stats="$(_brew_installed_stats cask "$name")"
      fi
      (( ${#pkg_stats} > max_stats )) && max_stats=${#pkg_stats}
    fi

    # Use a non-whitespace separator so empty fields are preserved when splitting.
    rows+=("${type}${field_sep}${name}${field_sep}${pkg_stats}${field_sep}${desc}")
    (( ${#name} > max_name )) && max_name=${#name}
    processed=$((processed + 1))
  done < <(
    jq -r '
      ((.formulae // [])[] | ["0", .name, (.desc // "")] | @tsv),
      ((.casks // [])[]    | ["1", .token, (.desc // "")] | @tsv)
    ' <<<"$info_json" \
      | LC_ALL=C sort -t $'\t' -k1,1 -k2,2
  )

  # Keep alignment stable even if analytics is requested but nothing is cached yet.
  if (( show_analytics )); then
    (( max_stats < 5 )) && max_stats=5
  fi

  local row type name stats desc
  for row in "${rows[@]}"; do
    IFS=$field_sep read -r type name stats desc <<<"$row"
    if (( use_color )); then
      local name_color="$formula_color"
      [[ "$type" == "1" ]] && name_color="$cask_color"
      if (( show_analytics )); then
        printf "%s%-*s%s  %-*s  %s\n" "$name_color" "$max_name" "$name" "$reset" "$max_stats" "$stats" "$desc"
      else
        printf "%s%-*s%s  %s\n" "$name_color" "$max_name" "$name" "$reset" "$desc"
      fi
    else
      if (( show_analytics )); then
        printf "%-*s  %-*s  %s\n" "$max_name" "$name" "$max_stats" "$stats" "$desc"
      else
        printf "%-*s  %s\n" "$max_name" "$name" "$desc"
      fi
    fi
  done
}

# Lazy-load antidote properly
antidote() {
  unfunction antidote
  local _antidote_path="${BREW_PREFIX:-$(brew --prefix)}/opt/antidote/share/antidote/antidote.zsh"
  [[ -f "$_antidote_path" ]] || _antidote_path="${HOME}/.antidote/antidote.zsh"
  source "$_antidote_path"
  antidote "$@"
}

# bd init: default to --stealth -> beads stays local (.git/info/exclude), no auto-commit,
# no git hooks, no AGENTS.md/CLAUDE.md/.cursor/.codex/.agents clutter.
# Opt out for a shared/team tracker with: command bd init ...  (or pass --team/--contributor)
bd() {
  if [[ $1 == init && " $* " != *" --stealth "* && " $* " != *" --team "* && " $* " != *" --contributor "* ]]; then
    shift
    command bd init --stealth "$@"
  else
    command bd "$@"
  fi
}

# FIGlet banners through lolcat. `fig` picks from FIGLET_FUN_FONTS.
# `fig -A` picks any installed .flf. `fig -a` animates. `fig -f doom hello` pins a font.
# Font name is printed on stderr. Static lolcat (the `lol` alias animates and inverts).
FIGLET_FUN_FONTS=(
  slant doom starwars larry3d isometric1 graffiti poison nancyj-fancy
  banner3-D big block bubble chunky cosmic cyberlarge epic fuzzy gothic
  hollywood invita ogre puffy relief roman rounded rowancap script shadow
  speed standard stellar smslant smshadow small crawford drpepper fraktur
  bulbhead broadway alligator avatar digital dotmatrix lean rectangles
  rozzo stampatello stop thick computer cricket
)

fig() {
  emulate -L zsh
  setopt local_options null_glob pipefail

  local font="" animate=0 any=0 list=0
  while (( $# )); do
    case $1 in
      -f|--font)
        shift
        (( $# )) || { print -u2 "fig: -f needs a font name"; return 2 }
        font=$1
        shift
        ;;
      -a|--animate) animate=1; shift ;;
      -A|--any) any=1; shift ;;
      -l|--list) list=1; shift ;;
      --) shift; break ;;
      -*)
        print -u2 "usage: fig [-a] [-A] [-f font] [-l] [message...]"
        return 2
        ;;
      *) break ;;
    esac
  done

  if (( list )); then
    print -l -- "${FIGLET_FUN_FONTS[@]}"
    return 0
  fi

  if [[ $# -eq 0 && -t 0 ]]; then
    print -u2 "usage: fig [-a] [-A] [-f font] [-l] [message...]"
    return 2
  fi

  if [[ -z $font ]]; then
    local -a pool
    if (( any )); then
      local dir
      dir=$(command figlet -I2) || return 1
      local -a files
      files=("$dir"/*.flf)
      (( ${#files} )) || { print -u2 "fig: no fonts in $dir"; return 1 }
      pool=("${files[@]:t:r}")
    else
      pool=("${FIGLET_FUN_FONTS[@]}")
    fi
    font=${pool[$((RANDOM % ${#pool} + 1))]}
    print -u2 -- "$font"
  fi

  local width=${COLUMNS:-80}
  local -a paint=(command lolcat -t -F 0.5 -p 5)
  (( animate )) && paint+=(-a -d 6 -s 10)

  command figlet -w "$width" -c -f "$font" "$@" | "${paint[@]}"
}

alias figa='fig -a'
alias figany='fig -A'
alias figfonts='fig -l'
alias figslant='fig -f slant'
alias figdoom='fig -f doom'
alias figwars='fig -f starwars'
alias figiso='fig -f isometric1'
alias fig3d='fig -f larry3d'
alias figpoison='fig -f poison'
alias figgraf='fig -f graffiti'
alias fignancy='fig -f nancyj-fancy'
alias figbig='fig -f big'
alias figsms='fig -f smslant'

# Terminal AI editing widgets (^X^S rewrite, ^X^I instruct, ai: prefix).
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/slop.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/slop.zsh"
