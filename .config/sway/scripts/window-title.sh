#!/usr/bin/env sh
# Window title watcher for waybar
# Subscribes to sway window and workspace events and updates waybar on focus changes

# Initial signal to populate module on startup
waybar-signal window-title

# Subscribe to window and workspace events and update on each relevant change
swaymsg -t subscribe -m '["window","workspace"]' | while read -r event; do
    # Get event type
    event_type=$(echo "$event" | jq -r '.change')

    # Update on:
    # - window focus/title changes
    # - workspace focus changes (switching to empty workspace)
    if [ "$event_type" = "focus" ] || [ "$event_type" = "title" ]; then
        waybar-signal window-title
    fi
done
