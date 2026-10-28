# History/options tuning
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt APPEND_HISTORY             # Append on exit; Zsh may still rewrite when trimming.
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_SAVE_BY_COPY HIST_FCNTL_LOCK
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME # SHARE_HISTORY owns incremental writes
unsetopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS # Preserve ordering for contextual suggestions
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_VERIFY               # Show command with history expansion to user before running it
setopt HIST_REDUCE_BLANKS        # Trim extra blanks
setopt HIST_NO_FUNCTIONS         # Don't store function definitions in history
