#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
starship_cache="$tmpdir/starship-cache"
trap 'rm -rf "$tmpdir"' EXIT

strip_prompt_escapes() {
  perl -pe 's/%\{[^}]*%\}//g; s/\e\[[0-9;]*m//g'
}

check_prompt_lines() {
  local name="$1"
  local config="$2"
  local rendered
  local line_number=0
  local lines=()

  rendered="$(
    STARSHIP_CONFIG="$config" \
      STARSHIP_CACHE="$starship_cache" \
      TERM=xterm-256color \
      starship prompt \
        --status=0 \
        --cmd-duration=1200 \
        --terminal-width=200 \
        --path "$repo_root" \
      | strip_prompt_escapes
  )"

  mapfile -t lines <<<"$rendered"
  if (( ${#lines[@]} < 2 )); then
    echo "$name: expected a multiline prompt, got ${#lines[@]} line(s)" >&2
    return 1
  fi

  for line in "${lines[@]:0:${#lines[@]}-1}"; do
    ((line_number += 1))
    if [[ "$line" == " "* ]]; then
      echo "$name line $line_number starts with padding: [$line]" >&2
      return 1
    fi
    if [[ "$line" == *" " ]]; then
      echo "$name line $line_number ends with padding: [$line]" >&2
      return 1
    fi
  done
}

chezmoi execute-template --file "$repo_root/dot_config/starship.toml.tmpl" >"$tmpdir/starship.toml"

check_prompt_lines "starship.toml.tmpl" "$tmpdir/starship.toml"
check_prompt_lines "starship-remote.toml" "$repo_root/dot_config/starship-remote.toml"
check_prompt_lines "starship-mosh.toml" "$repo_root/dot_config/starship-mosh.toml"
