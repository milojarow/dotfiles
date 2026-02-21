#!/usr/bin/env bash
# Show app name for 3 seconds when window-title bar is clicked

OVERRIDE_FILE="/tmp/waybar-window-title-override-$USER"

# If already in override mode, cancel it immediately
if [ -f "$OVERRIDE_FILE" ]; then
    rm -f "$OVERRIDE_FILE"
    pkill -RTMIN+10 waybar 2>/dev/null || true
    exit 0
fi

# Get current focused window
info=$(swaymsg -t get_tree | jq -r '
    [.. | select(.focused? == true and .pid?)] | first // empty |
    [(.app_id // .window_properties.class // ""), (.name // "")] | @tsv
')
[ -z "$info" ] && exit 0

IFS=$'\t' read -r app_id _title <<< "$info"

get_app_name() {
    case "${1,,}" in
        *footclient*|*foot*)  echo "Foot terminal" ;;
        *ghostty*)            echo "Ghostty terminal" ;;
        *alacritty*)          echo "Alacritty" ;;
        *kitty*)              echo "Kitty terminal" ;;
        *firefox*)            echo "Firefox" ;;
        *chromium*)           echo "Chromium" ;;
        *brave*)              echo "Brave Browser" ;;
        *code*|*vscode*)      echo "VS Code" ;;
        *vlc*)                echo "VLC" ;;
        *discord*)            echo "Discord" ;;
        *spotify*)            echo "Spotify" ;;
        *obsidian*)           echo "Obsidian" ;;
        *thunar*)             echo "Thunar" ;;
        *nautilus*)           echo "Nautilus" ;;
        *mpv*)                echo "mpv" ;;
        *gimp*)               echo "GIMP" ;;
        *inkscape*)           echo "Inkscape" ;;
        *)                    echo "$1" ;;
    esac
}

app_name=$(get_app_name "$app_id")
expires=$(($(date +%s) + 3))

# Write override file: line 1 = display text, line 2 = expiry timestamp
printf '%s\n%s\n' "$app_name" "$expires" > "$OVERRIDE_FILE"

# Show override in waybar
pkill -RTMIN+10 waybar 2>/dev/null || true

# After 3 seconds, clear override and restore real title
(
    sleep 3
    rm -f "$OVERRIDE_FILE"
    pkill -RTMIN+10 waybar 2>/dev/null || true
) &
