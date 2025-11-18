#!/usr/bin/env bash

# Monitor clipboard for image copies and notify
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

# Cleanup on exit
trap "rm -f '$CALLBACK_SCRIPT'" EXIT INT TERM

wl-paste --watch "$CALLBACK_SCRIPT"
