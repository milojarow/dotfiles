#!/usr/bin/env bash

LOCKFILE="/tmp/screenshot-notify.lock"
DIR=${XDG_SCREENSHOTS_DIR:-$HOME/Screenshots}

# Exit if already running
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
    exit 0
fi

# Write our PID and setup cleanup
echo $$ > "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT INT TERM

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
            notify-send "Screenshot saved" "$FILE"
            ;;
    esac
done
