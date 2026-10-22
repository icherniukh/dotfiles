#!/usr/bin/env zsh
#
# Terminal AI editing widgets.
#
#   ^X^E      AI Rewrite  - replace the current command line with an AI rewrite
#   ^X^I      AI Instruct - same, but asks for the instruction first
#   ai: TEXT  + Enter     - rewrite TEXT in place after an instruction prompt
#
# Ctrl-X Ctrl-S is deliberately avoided: it is XOFF (terminal flow control) and
# swallows the next keystroke.

# Default instruction used by ^X^E and the ai: prefix.
_slop_default_instruction() {
  print -r -- "Rewrite this so it reads like a competent human wrote it. Remove AI writing patterns: canned openings, binary contrasts, fake importance, weasel attribution, colon reveals, inflated vocabulary, and filler adverbs. Keep the meaning, keep the voice, make the minimum effective edit."
}

# Read one line from the terminal with ZLE suspended, so the prompt is clean.
# The result lands in _SLOP_REPLY.
#
# This must run in the current shell, not in a command substitution: a
# subshell puts the read on a different fd, and the terminating newline never
# ends the read, so the answer runs into whatever is typed next.
_slop_read_line() {
  _SLOP_REPLY=""
  zle -I
  print -n -- "$1" >/dev/tty
  IFS= read -r _SLOP_REPLY </dev/tty
}

# Run text through plz and put the result in _SLOP_RESULT. Returns non-zero on
# failure and leaves the original buffer untouched.
_slop_transform() {
  local instruction="$1" original="$2"

  _SLOP_RESULT=""

  if [[ -z "$original" ]]; then
    print -n -- "slop: nothing to rewrite" >&2
    return 1
  fi

  if ! command -v plz >/dev/null 2>&1; then
    print -n -- "slop: plz not found on PATH" >&2
    return 1
  fi

  _SLOP_RESULT="$(printf '%s' "$original" | plz "$instruction" 2>/dev/null)"

  if [[ -z "$_SLOP_RESULT" ]]; then
    print -n -- "slop: the model returned nothing" >&2
    return 1
  fi

  return 0
}

# ^X^E - rewrite the buffer with the default slop instruction.
_slop_rewrite_widget() {
  local original="$BUFFER"

  zle -I
  print -n -- "rewriting..." >/dev/tty
  if _slop_transform "$(_slop_default_instruction)" "$original"; then
    BUFFER="$_SLOP_RESULT"
  fi
  zle redisplay
}

# ^X^I - ask for an instruction, then rewrite the buffer with it.
_slop_instruct_widget() {
  local original="$BUFFER"

  _slop_read_line 'instruction> '

  if [[ -z "$_SLOP_REPLY" ]]; then
    zle redisplay
    return 0
  fi

  zle -I
  print -n -- "working..." >/dev/tty
  if _slop_transform "$_SLOP_REPLY" "$original"; then
    BUFFER="$_SLOP_RESULT"
  fi
  zle redisplay
}

# Override accept-line: a line starting with "ai:" is text to rewrite, not a
# command. Prompts for the instruction, puts the rewrite back in the buffer,
# and leaves the line on screen so the user can review it before running it.
_slop_enter_widget() {
  local original result

  if [[ "$BUFFER" != ai:* ]]; then
    zle accept-line
    return
  fi

  original="${BUFFER#ai:}"
  original="${original# }"

  _slop_read_line 'instruction> '

  if [[ -z "$_SLOP_REPLY" ]]; then
    BUFFER="ai: ${original}"
    zle redisplay
    return 0
  fi

  zle -I
  print -n -- "working..." >/dev/tty
  if _slop_transform "$_SLOP_REPLY" "$original"; then
    BUFFER="$_SLOP_RESULT"
  else
    BUFFER="ai: ${original}"
  fi
  zle redisplay
}

zle -N _slop_rewrite_widget
zle -N _slop_instruct_widget
zle -N _slop_enter_widget
bindkey '^X^E' _slop_rewrite_widget 2>/dev/null
bindkey '^X^I' _slop_instruct_widget 2>/dev/null
bindkey '^M' _slop_enter_widget 2>/dev/null
bindkey '^J' _slop_enter_widget 2>/dev/null
