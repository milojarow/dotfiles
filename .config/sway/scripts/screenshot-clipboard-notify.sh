#!/usr/bin/env bash

# Monitor clipboard for image copies and notify
LOCKFILE="/tmp/screenshot-clipboard-notify.lock"

# Check if already running
if [ -f "$LOCKFILE" ]; then
    OLD_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        # Another instance is running, kill it and its children
        pkill -P "$OLD_PID" 2>/dev/null || true
        kill "$OLD_PID" 2>/dev/null || true
        sleep 0.5
    fi
    # Remove stale lockfile
    rm -f "$LOCKFILE"
fi

# Kill any orphaned wl-paste processes from previous runs
pkill -f "wl-paste.*clipboard-notify-callback" 2>/dev/null || true

# Write our PID and setup cleanup
echo $$ > "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT INT TERM

# Export necessary environment variables for notify-send
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

# Create a callback script that will be executed by wl-paste --watch
CALLBACK_SCRIPT="/tmp/clipboard-notify-callback-$$.sh"
cat > "$CALLBACK_SCRIPT" << 'EOF'
#!/bin/bash
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

MIME=$(wl-paste -l | head -1)
if [[ "$MIME" == "image/png" ]]; then
    NOW=$(date +%s%N)
    LAST=$(cat /tmp/screenshot-clipboard-last 2>/dev/null || echo 0)
    DIFF=$((NOW - LAST))
    if [[ $DIFF -gt 100000000 ]]; then
        echo $NOW > /tmp/screenshot-clipboard-last
        notify-send "Screenshot copied to clipboard"
    fi
fi
EOF

chmod +x "$CALLBACK_SCRIPT"

# Update trap to cleanup both lockfile and callback script
trap "rm -f '$LOCKFILE' '$CALLBACK_SCRIPT'" EXIT INT TERM

wl-paste --watch "$CALLBACK_SCRIPT"
