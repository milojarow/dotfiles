#!/usr/bin/env sh
# Thin reader for waybar custom/window-title module
# The actual processing is done by window-title.sh which caches results here

OVERRIDE_FILE="/tmp/waybar-window-title-override-$USER"

# Check if click override is active and not expired
if [ -f "$OVERRIDE_FILE" ]; then
    override_text=$(sed -n '1p' "$OVERRIDE_FILE")
    expires=$(sed -n '2p' "$OVERRIDE_FILE")
    now=$(date +%s)
    if [ -n "$expires" ] && [ "$now" -lt "$expires" ]; then
        printf '{"text":"%s","tooltip":"App name (click to dismiss)","class":"window-title app-flash"}\n' "$override_text"
        exit 0
    else
        rm -f "$OVERRIDE_FILE"
    fi
fi

cat "/tmp/waybar-window-title-$USER.json" 2>/dev/null || \
    printf '{"text":"","tooltip":"No focused window","class":"empty"}\n'
