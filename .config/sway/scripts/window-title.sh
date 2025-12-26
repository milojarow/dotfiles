#!/usr/bin/env sh
# Window title watcher for waybar
# Subscribes to sway window events and updates waybar on focus changes

# Initial signal to populate module on startup
waybar-signal window-title

# Subscribe to window events and update on each relevant change
swaymsg -t subscribe -m '["window"]' | while read -r event; do
    # Only update on focus and title changes (ignore move, resize, etc.)
    event_type=$(echo "$event" | jq -r '.change')
    if [ "$event_type" = "focus" ] || [ "$event_type" = "title" ]; then
        waybar-signal window-title
    fi
done
