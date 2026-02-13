#!/usr/bin/env bash

LOCKFILE="/tmp/screenshot-notify.lock"
DIR=${XDG_SCREENSHOTS_DIR:-$HOME/Screenshots}

# Exit if already running
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
    exit 0
fi

# Write our PID and setup cleanup
echo $$ > "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT
trap "rm -f '$LOCKFILE'; exit 0" INT TERM

# Export necessary environment variables for notify-send
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"
export DISPLAY="${DISPLAY}"

mkdir -p "$DIR"

# Monitor for file saves
while true; do
    FILE=$(inotifywait -q -e close_write --format '%f' "$DIR" 2>&1)
    case "$FILE" in
        *.png)
            # Debounce to prevent duplicate notifications (100ms threshold)
            NOW=$(date +%s%N)
            LAST=$(cat /tmp/screenshot-save-last 2>/dev/null || echo 0)
            DIFF=$((NOW - LAST))
            if [[ $DIFF -gt 100000000 ]]; then
                echo $NOW > /tmp/screenshot-save-last
                notify-send "Screenshot saved" "$FILE"
            fi
            ;;
    esac
done
