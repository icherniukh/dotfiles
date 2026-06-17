# History/options tuning
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY_TIME   # Append each command after it finishes, preserving duration
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_VERIFY               # Show command with history expansion to user before running it
setopt HIST_REDUCE_BLANKS        # Trim extra blanks
setopt HIST_NO_FUNCTIONS         # Don't store function definitions in history
unsetopt INC_APPEND_HISTORY      # Mutually exclusive with INC_APPEND_HISTORY_TIME