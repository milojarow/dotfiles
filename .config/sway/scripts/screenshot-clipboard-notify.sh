#!/usr/bin/env bash

# Monitor clipboard for image copies and notify
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

wl-paste --watch bash -c 'export DBUS_SESSION_BUS_ADDRESS="'"$DBUS_SESSION_BUS_ADDRESS"'"; export WAYLAND_DISPLAY="'"$WAYLAND_DISPLAY"'"; MIME=$(wl-paste -l | head -1); if [[ "$MIME" == "image/png" ]]; then NOW=$(date +%s%N); LAST=$(cat /tmp/screenshot-clipboard-last 2>/dev/null || echo 0); DIFF=$((NOW - LAST)); if [[ $DIFF -gt 100000000 ]]; then echo $NOW > /tmp/screenshot-clipboard-last; notify-send "Screenshot copied to clipboard"; fi; fi'
