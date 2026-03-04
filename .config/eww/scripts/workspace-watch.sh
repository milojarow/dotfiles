#!/bin/bash
# Opens/closes an eww window based on the active sway workspace.
# Usage: workspace-watch.sh <window-name> <workspace-number>

WINDOW="${1}"
TARGET_WS="${2}"

# Kill any previous instance of this script (avoid duplicates on exec_always)
for pid in $(pgrep -f "workspace-watch.sh ${WINDOW} ${TARGET_WS}"); do
    [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null
done

# Check current workspace at startup
current=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .num')
if [ "$current" = "$TARGET_WS" ]; then
    eww open "$WINDOW"
else
    eww close "$WINDOW" 2>/dev/null
fi

# Watch for workspace changes
swaymsg -t subscribe -m '["workspace"]' \
  | jq --unbuffered -r '.current.num' \
  | while read -r ws; do
      if [ "$ws" = "$TARGET_WS" ]; then
          eww open "$WINDOW"
      else
          eww close "$WINDOW" 2>/dev/null
      fi
    done
