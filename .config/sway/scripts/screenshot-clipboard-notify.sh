#!/usr/bin/env bash

# Monitor clipboard for image copies and notify
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

wl-paste --watch bash -c '
    MIME=$(wl-paste -l | head -1)
    if [[ "$MIME" == "image/png" ]]; then
        notify-send "Screenshot copied to clipboard"
    fi
'
