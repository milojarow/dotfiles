#!/usr/bin/env bash
# ── Window Title ─────────────────────────────────────────────────────────────
# Role:     Right-click handler — opens a rofi text input to assign a custom
#           context label to the focused window; empty submit clears the label;
#           preserves the location prefix, replaces only the context part
# Files:    window-title.sh · window-title-output.sh · window-title-click.sh
#           window-title-rename.sh
#           ~/.config/waybar/config.jsonc               (custom/window-title, signal 10)
#           ~/.config/sway/config.d/99-autostart-applications.conf
# Programs: swaymsg  jq  pgrep  pstree  pkill  rofi
# Callers:  waybar on-click-right (config.jsonc custom/window-title)
# Man:      man window-title
# ─────────────────────────────────────────────────────────────────────────────

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

# Default input: existing custom context, or current context extracted from waybar cache
current_ctx=""
if [ -f "$NAMES_DIR/$win_id.name" ]; then
    current_ctx=$(cat "$NAMES_DIR/$win_id.name" 2>/dev/null)
elif [ -f "$CACHE_FILE" ]; then
    current_text=$(jq -r '.text // ""' "$CACHE_FILE" 2>/dev/null)
    if [[ "$current_text" == *": "* ]]; then
        current_ctx="${current_text#*: }"
    else
        current_ctx="$current_text"
    fi
fi

# Show rofi text input just below waybar (north anchor, centered)
new_name=$(rofi \
    -dmenu \
    -theme-str 'window {location: north; anchor: north; y-offset: 40px; width: 360px;}' \
    -theme-str 'listview {lines: 0;}' \
    -theme-str 'inputbar {padding: 10px 14px;}' \
    -p "Window name:" \
    -filter "$current_ctx")

# Escape or cancel → no change
[ $? -ne 0 ] && exit 0

if [ -z "$new_name" ]; then
    # Empty submit → clear name, trigger re-render via window-title.sh USR1 handler
    rm -f "$NAMES_DIR/$win_id.name"
    pkill -USR1 -f "window-title.sh" 2>/dev/null
    pkill -RTMIN+10 waybar 2>/dev/null || true
    exit 0
fi

# Save custom context (just the label, not the full display)
mkdir -p "$NAMES_DIR"
printf '%s' "$new_name" > "$NAMES_DIR/$win_id.name"

# Build display text preserving location prefix from current cache
location_prefix=""
if [ -f "$CACHE_FILE" ]; then
    current_text=$(jq -r '.text // ""' "$CACHE_FILE" 2>/dev/null)
    [[ "$current_text" == *": "* ]] && location_prefix="${current_text%%: *}"
fi

if [ -n "$location_prefix" ]; then
    display_text="$location_prefix: $new_name"
else
    display_text="$new_name"
fi

_escaped="${display_text//\\/\\\\}"
_escaped="${_escaped//\"/\\\"}"
printf '{"text":"%s","tooltip":"%s","class":"window-title custom-named"}\n' \
    "$_escaped" "${app_id:-window}" \
    > "$CACHE_TMP" && mv "$CACHE_TMP" "$CACHE_FILE"

pkill -RTMIN+10 waybar 2>/dev/null || true
