#!/bin/zsh
# @raycast.schemaVersion 1
# @raycast.title Artifact Save
# @raycast.mode silent
# @raycast.icon 📦
# @raycast.packageName Artifacts
# @raycast.description Save the clipboard to ~/ai_infra/artifacts/
# @raycast.argument1 { "type": "text", "placeholder": "name (optional)", "optional": true }

exec "$HOME/.scripts/artifact-save" -c "$@"
