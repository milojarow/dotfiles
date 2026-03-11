#!/usr/bin/env bash
# Left-click handler for eww window title — flashes the app name for 3 seconds.
# Uses a file with expiry timestamp (mirrors waybar approach). The defpoll in
# bar.yuck reads this file every 500ms and auto-expires it without needing a
# background process.

FLASH_FILE="/tmp/eww-window-title-flash-${USER}"

# If already flashing, dismiss immediately
if [ -f "$FLASH_FILE" ]; then
    rm -f "$FLASH_FILE"
    exit 0
fi

# Get app_id of focused window
app_id=$(swaymsg -t get_tree | jq -r '
    [.. | select(.focused? == true and .pid?)] | first // empty |
    (.app_id // .window_properties.class // "")
')
[ -z "$app_id" ] && exit 0

get_app_name() {
    case "${1,,}" in
        *footclient*|*foot*)   echo "Foot terminal" ;;
        *ghostty*)             echo "Ghostty terminal" ;;
        *alacritty*)           echo "Alacritty" ;;
        *kitty*)               echo "Kitty terminal" ;;
        *firefox*|*librewolf*) echo "Firefox" ;;
        *brave*)               echo "Brave Browser" ;;
        *chromium*)            echo "Chromium" ;;
        *code*|*vscodium*)     echo "VS Code" ;;
        *vlc*)                 echo "VLC" ;;
        *obsidian*)            echo "Obsidian" ;;
        *telegram*)            echo "Telegram" ;;
        *discord*)             echo "Discord" ;;
        *mpv*)                 echo "mpv" ;;
        *)                     echo "$1" ;;
    esac
}

app_name=$(get_app_name "$app_id")
expires=$(($(date +%s) + 3))
printf '%s\n%s\n' "$app_name" "$expires" > "$FLASH_FILE"
