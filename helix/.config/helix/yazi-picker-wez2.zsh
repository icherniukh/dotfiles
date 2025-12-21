#!/usr/bin/env zsh

# Function to run Yazi in a new WezTerm pane
run_yazi() {
    wezterm cli split-pane --horizontal --percent 80 --top-level -- zsh -c "yazi --chooser-file=/tmp/yazi_chosen_files"
}

# Run Yazi and wait for it to finish
run_yazi
wait

# Read the chosen files
paths=$(cat /tmp/yazi_chosen_files | while read -r line; do printf "%q " "$line"; done)

# Clean up the temporary file
rm /tmp/yazi_chosen_files

if [[ -n "$paths" ]]; then
    # Close the Yazi pane
    wezterm cli kill-pane --pane-id $WEZTERM_PANE

    # Activate the original pane
    wezterm cli activate-pane-direction --pane-id $WEZTERM_PANE up

    # Send the command to the original pane
    wezterm cli send-text --no-paste $'\e' # send <Escape> key
    wezterm cli send-text --no-paste ":open $paths"
    wezterm cli send-text --no-paste $'\r' # send <Enter> key
else
    # If no files were chosen, just close the Yazi pane
    wezterm cli kill-pane --pane-id $WEZTERM_PANE
fi
