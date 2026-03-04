#!/usr/bin/env bash
# Assign a custom display name to the currently focused sway window.
# Called via right-click on the waybar window-title module.
# Names persist in /tmp/waybar-window-names-$USER/ for the sway session lifetime.

NAMES_DIR="/tmp/waybar-window-names-$USER"
CACHE_FILE="/tmp/waybar-window-title-$USER.json"
CACHE_TMP="${CACHE_FILE}.tmp"

# Get focused window ID and app_id from sway tree
info=$(swaymsg -t get_tree | jq -r '
    [.. | select(.focused? == true and .pid?)] | first // empty |
    [(.id|tostring), (.app_id // .window_properties.class // "")] | @tsv
')
[ -z "$info" ] && exit 0

IFS=$'\t' read -r win_id app_id <<< "$info"

# Read current custom name as default input
current_name=""
[ -f "$NAMES_DIR/$win_id.name" ] && current_name=$(cat "$NAMES_DIR/$win_id.name" 2>/dev/null)

# Show rofi text input just below waybar (north anchor, centered)
new_name=$(rofi \
    -dmenu \
    -theme-str 'window {location: north; anchor: north; y-offset: 40px; width: 360px;}' \
    -theme-str 'listview {lines: 0;}' \
    -theme-str 'inputbar {padding: 10px 14px;}' \
    -p "Window name:" \
    -filter "$current_name")

# Escape or cancel → no change
[ $? -ne 0 ] && exit 0

if [ -z "$new_name" ]; then
    # Empty submit → clear name, trigger re-render via window-title.sh USR1 handler
    rm -f "$NAMES_DIR/$win_id.name"
    pkill -USR1 -f "window-title.sh" 2>/dev/null
    pkill -RTMIN+10 waybar 2>/dev/null || true
    exit 0
fi

# Save custom name and update waybar immediately (no wait for sway event)
mkdir -p "$NAMES_DIR"
printf '%s' "$new_name" > "$NAMES_DIR/$win_id.name"

_escaped="${new_name//\\/\\\\}"
_escaped="${_escaped//\"/\\\"}"
printf '{"text":"%s","tooltip":"%s","class":"window-title custom-named"}\n' \
    "$_escaped" "${app_id:-window}" \
    > "$CACHE_TMP" && mv "$CACHE_TMP" "$CACHE_FILE"

pkill -RTMIN+10 waybar 2>/dev/null || true
