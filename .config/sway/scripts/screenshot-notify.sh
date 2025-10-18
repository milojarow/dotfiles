#!/usr/bin/env bash

LOCKFILE="/tmp/screenshot-notify.lock"
LOGFILE="/tmp/screenshot-notify.log"
DIR=${XDG_SCREENSHOTS_DIR:-$HOME/Screenshots}

# Exit if already running
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
    echo "$(date): Already running, exiting" >> "$LOGFILE"
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

echo "$(date): Starting screenshot-notify daemon, watching $DIR" >> "$LOGFILE"
echo "$(date): DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS" >> "$LOGFILE"
echo "$(date): WAYLAND_DISPLAY=$WAYLAND_DISPLAY" >> "$LOGFILE"

# Simple inotifywait loop
while true; do
    FILE=$(inotifywait -q -e close_write --format '%f' "$DIR" 2>&1)
    echo "$(date): Detected file event: $FILE" >> "$LOGFILE"
    case "$FILE" in
        *.png)
            echo "$(date): Sending notification for: $FILE" >> "$LOGFILE"
            notify-send "Screenshot saved" "$FILE"
            ;;
        *)
            echo "$(date): Ignored non-png file: $FILE" >> "$LOGFILE"
            ;;
    esac
done
