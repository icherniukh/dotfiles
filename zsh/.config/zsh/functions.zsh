#!/usr/bin/env zsh

source $HOME/.config/wezaliases.zsh

# functions.zsh: Publicly-safe functions.
# (Internal Amazon API functions moved to git-ignored local.zsh)

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

addalias() {
    # Check for correct number of arguments
    if [ "$#" -ne 2 ]; then
        echo "Usage: addalias <alias_name> '<command>'"
        echo "Example: addalias gp 'git push'"
        return 1
    fi

    local alias_name="$1"
    local alias_command="$2"
    local alias_file="$HOME/.config/zsh/aliases.zsh"

    # Check if alias already exists
    if grep -q "alias ${alias_name}=" "$alias_file"; then
        echo "Error: Alias '${alias_name}' already exists."
        return 1
    fi

    # Prompt for description
    echo -n "Enter a description for alias '${alias_name}': "
    read -r description

    # Append the alias and description to the managed section at EOF.
    # Escape any single-quotes in the command for safe single-quoted alias.
    local escaped=${alias_command//\'/\'\\\'\'}
    {
      printf '\n# %s\n' "$description"
      printf "alias %s='%s'\n" "$alias_name" "$escaped"
    } >> "$alias_file"

    # Source the file to make the new alias available
    source "$alias_file"

    echo "Successfully added alias '${alias_name}'."
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
      if mtime="$(stat -f %m "$cache_file" 2>/dev/null)"; then
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
