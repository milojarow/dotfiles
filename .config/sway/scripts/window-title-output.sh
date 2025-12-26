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

# Get working directory from terminal foreground process
get_process_cwd() {
    if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
        # For terminals, we need to find the foreground shell process, not the terminal itself
        # Find all child processes and get the deepest one (usually the active shell)

        # Get all descendant PIDs
        children=$(pgrep -P "$pid" 2>/dev/null)

        if [ -n "$children" ]; then
            # Look for shell processes (fish, bash, zsh, sh) among children
            for child_pid in $children; do
                # Check if it's a shell
                cmd=$(ps -p "$child_pid" -o comm= 2>/dev/null)
                case "$cmd" in
                    fish|bash|zsh|sh)
                        # Found a shell, get its cwd
                        cwd=$(readlink -f "/proc/$child_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|")
                        if [ -n "$cwd" ] && [ "$cwd" != "~" ]; then
                            echo "$cwd"
                            return
                        fi
                        ;;
                esac
            done
        fi

        # Fallback: use terminal's own cwd
        if [ -d "/proc/$pid" ]; then
            readlink -f "/proc/$pid/cwd" 2>/dev/null | sed "s|^$HOME|~|"
        fi
    fi
}

# Extract directory from terminal title
# Handles formats: "~/path: cmd", "~/path - shell", "~ - fish", etc.
extract_path_from_title() {
    local t="$1"

    # Pattern 1: "~/path: anything" or "/path: anything"
    if echo "$t" | grep -qE '^[~/][^:]*:'; then
        echo "$t" | sed -E 's/^([~/][^:]*):.*$/\1/'
        return
    fi

    # Pattern 2: "~/path - shell" or "/path - shell"
    if echo "$t" | grep -qE '^[~/].* - (fish|bash|zsh|sh)$'; then
        echo "$t" | sed -E 's/^([~/].*) - (fish|bash|zsh|sh)$/\1/'
        return
    fi

    # Pattern 3: Just "~ - fish" (home directory)
    if echo "$t" | grep -qE '^~ - '; then
        echo "~"
        return
    fi

    # No path found in title
    return 1
}

# Build display text
# For terminals: extract path from title (most reliable), fallback to /proc
# For other apps: use window title as-is
case "$app_id" in
    *terminal* | *foot* | *alacritty* | *kitty* | *ghostty*)
        # Try to extract path from title first
        cwd=$(extract_path_from_title "$title")

        # If no path in title, try /proc as fallback
        if [ -z "$cwd" ]; then
            cwd=$(get_process_cwd)
        fi

        if [ -n "$cwd" ]; then
            # Show directory + rest of title after path
            # Extract what comes after the path (command, shell, etc)
            suffix=$(echo "$title" | sed -E "s|^[~/][^:]*:? ?(.*)$|\1|" | sed 's/^ *- *//')
            if [ -n "$suffix" ] && [ "$suffix" != "$title" ]; then
                display_text="$cwd: $suffix"
            else
                display_text="$cwd"
            fi
        else
            # Complete fallback: use title as-is
            display_text="$title"
        fi
        ;;
    *)
        # Not a terminal, use title as-is
        display_text="$title"
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
