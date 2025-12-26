#!/usr/bin/env sh
# Output focused window title in JSON format for waybar
# Shows path + command for terminals to help identify context

get_focused_info() {
    swaymsg -t get_tree | jq -r '
        .. | select(.focused? == true) |
        {
            name: .name // "",
            app_id: .app_id // "",
            class: .window_properties.class // "",
            pid: .pid // 0
        }
    '
}

info=$(get_focused_info)
title=$(echo "$info" | jq -r '.name')
app_id=$(echo "$info" | jq -r '.app_id')
class=$(echo "$info" | jq -r '.class')
pid=$(echo "$info" | jq -r '.pid')

# If no focused window (empty workspace)
if [ -z "$title" ] || [ "$title" = "null" ]; then
    printf '{"text":"", "tooltip":"No focused window", "class":"empty"}\n'
    exit 0
fi

# Get working directory from process if it's a terminal
get_process_cwd() {
    if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
        # Try to get cwd from /proc
        if [ -d "/proc/$pid" ]; then
            readlink -f "/proc/$pid/cwd" 2>/dev/null | sed "s|^$HOME|~|"
        fi
    fi
}

# Check if title already has directory format (path:command)
has_directory_in_title() {
    echo "$title" | grep -qE '^[~/].*:'
}

# Build display text based on whether terminal and whether dir is in title
display_text="$title"

# If it's a terminal app but title doesn't have directory, prepend the cwd
case "$app_id" in
    *terminal* | *foot* | *alacritty* | *kitty* | *ghostty*)
        if ! has_directory_in_title; then
            cwd=$(get_process_cwd)
            if [ -n "$cwd" ]; then
                # Prepend directory to title
                display_text="$cwd: $title"
            fi
        fi
        ;;
esac

# Truncate if too long (max 60 chars)
# For terminal titles with path:command format, try to preserve both path and command
if [ ${#display_text} -gt 60 ]; then
    # If it has a colon, try to keep path and first part of command
    if echo "$display_text" | grep -q ':'; then
        path_part=$(echo "$display_text" | cut -d':' -f1)
        command_part=$(echo "$display_text" | cut -d':' -f2- | sed 's/^ //')

        # If path is reasonable length, truncate command
        if [ ${#path_part} -lt 40 ]; then
            command_trunc=$(echo "$command_part" | cut -c1-17)
            display_text="${path_part}: ${command_trunc}..."
        else
            # Path itself is too long, truncate from left
            path_trunc=$(echo "$path_part" | tail -c 54)
            display_text="...${path_trunc}:..."
        fi
    else
        # No colon format, simple truncation
        display_text="${title:0:57}..."
    fi
fi

# Build tooltip with full information
app_name="${app_id:-$class}"
if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
    tooltip="${app_name}\n${title}"
else
    tooltip="$title"
fi

# Determine CSS class based on app type
css_class="window-title"
case "$app_id" in
    *terminal* | *foot* | *alacritty* | *kitty* | *ghostty*)
        css_class="window-title terminal"
        ;;
    *firefox* | *chromium* | *chrome* | *brave*)
        css_class="window-title browser"
        ;;
    *code* | *vim* | *nvim* | *helix*)
        css_class="window-title editor"
        ;;
esac

# Output JSON
printf '{"text":"%s", "tooltip":"%s", "class":"%s"}\n' \
    "$display_text" \
    "$(echo "$tooltip" | sed -z 's/\n/\\n/g')" \
    "$css_class"
