
wez_split_right () {
  wezterm cli split-pane --right $*
}

wezterm_open() {
    local target="$1"
    local current_dir="$(PWD)"

    if [[ -z "$target" ]]; then
        # No parameter, open in current directory
        wez_split_right --cwd "$current_dir"
    elif [[ -d "$target" ]]; then
        # Directory parameter, open in that directory
        wez_split_right --cwd "$target"
    elif [[ -f "$target" ]]; then
        # File parameter, open with Helix editor
        # wez_split_right --cwd "$(dirname "$target")" -- helix "$target"
        wez_split_right --cwd "$(PWD)" -- helix $full_path
    else
        echo "Invalid target: $target"
        return 1
    fi
}

wezterm_open_boring() {
    local target="$1"
    local current_dir="$(pwd)"

    if [[ -z "$target" ]]; then
        # No parameter, open in current directory
        wezterm cli split-pane --right --cwd "$current_dir"
    elif [[ -d "$target" ]]; then
        # Directory parameter, open in that directory
        wezterm cli split-pane --right --cwd "$target"
    elif [[ -f "$target" ]]; then
        # File parameter, open with Helix editor
        local full_path = $(where $target)
        wezterm cli split-pane --right --cwd "$(pwd)" -- helix $full_path
        # wezterm cli split-pane --right --cwd "$(pwd)" -- helix "$target"
    else
        echo "Invalid target: $target"
        return 1
    fi
}

# Alias for the wezterm_open function
alias wtopen="wezterm_open"
# alias wtopen="wezterm_open_boring"

# Alias to close the current pane (assuming you're in a WezTerm pane)
alias wtkill='wezterm cli kill-pane'
