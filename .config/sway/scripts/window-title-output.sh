#!/usr/bin/env sh
# Output focused window title in JSON format for waybar
# Shows path + command for terminals to help identify context

get_focused_info() {
    # Get the currently focused workspace name
    local focused_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused == true) | .name')

    # If no focused workspace, return empty
    if [ -z "$focused_ws" ]; then
        echo '{"id":0,"name":"","app_id":"","class":"","pid":0}'
        return
    fi

    # Get focused window info from tree
    # Filter to only windows within the focused workspace
    swaymsg -t get_tree | jq -c --arg ws "$focused_ws" '
        .. |
        select(.type? == "workspace" and .name? == $ws) |
        .. |
        select(.focused? == true and .pid?) |
        {
            id: .id,
            name: .name // "",
            app_id: .app_id // "",
            class: .window_properties.class // "",
            pid: .pid // 0
        }
    ' | head -1 || echo '{"id":0,"name":"","app_id":"","class":"","pid":0}'
}

info=$(get_focused_info)
window_id=$(echo "$info" | jq -r '.id')
title=$(echo "$info" | jq -r '.name')
app_id=$(echo "$info" | jq -r '.app_id')
class=$(echo "$info" | jq -r '.class')
pid=$(echo "$info" | jq -r '.pid')

# If no focused window (empty workspace)
if [ -z "$title" ] || [ "$title" = "null" ]; then
    printf '{"text":"", "tooltip":"No focused window", "class":"empty"}\n'
    exit 0
fi

# Get foreground command from terminal (ssh, vim, etc.)
get_foreground_command() {
    if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
        # Get all shell processes under terminal
        children=$(pgrep -P "$pid" 2>/dev/null)

        if [ -n "$children" ]; then
            # For each shell, check if it has an interactive command running
            for child_pid in $children; do
                cmd=$(ps -p "$child_pid" -o comm= 2>/dev/null)
                case "$cmd" in
                    fish|bash|zsh|sh)
                        # Check if shell has foreground children (ssh, vim, etc.)
                        shell_children=$(pgrep -P "$child_pid" -a 2>/dev/null)
                        if [ -n "$shell_children" ]; then
                            # Look for interactive commands
                            echo "$shell_children" | while read child_info; do
                                child_cmd=$(echo "$child_info" | awk '{print $2}')
                                case "$child_cmd" in
                                    ssh|vim|nvim|htop|top|less|man|nano|emacs|tmux|screen|claude)
                                        # Found interactive command, return full command line
                                        echo "$shell_children" | awk '{$1=""; print $0}' | sed 's/^ //'
                                        return
                                        ;;
                                esac
                            done
                        fi
                        ;;
                esac
            done
        fi
    fi
}

# Get working directory from terminal foreground process
# Uses process tree traversal to find the active shell's working directory
get_process_cwd() {
    if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
        # Get all descendant PIDs (not just direct children)
        all_descendants=$(pstree -p "$pid" 2>/dev/null | grep -oP '\(\K[0-9]+' | grep -v "^$pid$")

        if [ -n "$all_descendants" ]; then
            # Find shells and their commands
            best_shell_pid=""
            best_shell_cwd=""

            for desc_pid in $all_descendants; do
                cmd=$(ps -p "$desc_pid" -o comm= 2>/dev/null)
                case "$cmd" in
                    fish|bash|zsh|sh)
                        # Found a shell, check if it has children
                        shell_children=$(pgrep -P "$desc_pid" 2>/dev/null)

                        # Try to read PWD from process environment (more reliable for Fish)
                        shell_cwd=""
                        if [ -r "/proc/$desc_pid/environ" ]; then
                            shell_cwd=$(tr '\0' '\n' < "/proc/$desc_pid/environ" 2>/dev/null | grep '^PWD=' | cut -d= -f2- | sed "s|^$HOME|~|")
                        fi

                        # Fallback to readlink if PWD not available
                        if [ -z "$shell_cwd" ]; then
                            shell_cwd=$(readlink -f "/proc/$desc_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|")
                        fi

                        # Prioritize shells WITHOUT children (at prompt)
                        if [ -z "$shell_children" ] && [ -n "$shell_cwd" ]; then
                            best_shell_pid="$desc_pid"
                            best_shell_cwd="$shell_cwd"
                            break
                        elif [ -z "$best_shell_pid" ] && [ -n "$shell_cwd" ]; then
                            # Shell with children - remember as fallback
                            best_shell_pid="$desc_pid"
                            best_shell_cwd="$shell_cwd"
                        fi
                        ;;
                esac
            done

            # Return best shell's CWD
            if [ -n "$best_shell_cwd" ]; then
                echo "$best_shell_cwd"
                return
            fi
        fi

        # Fallback: use terminal's own cwd
        if [ -d "/proc/$pid" ]; then
            readlink -f "/proc/$pid/cwd" 2>/dev/null | sed "s|^$HOME|~|"
        fi
    fi
}

# Cache directory for window locations
CACHE_DIR="/tmp/waybar-window-locations-$USER"

# Ensure cache directory exists
ensure_cache_dir() {
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR" 2>/dev/null
    fi
}

# Write location to cache for a window
# Args: window_id, location
cache_location() {
    local win_id="$1"
    local loc="$2"

    # Only cache real locations (not fallback "claude")
    # Note: "~" is a valid location and should be cached
    if [ -z "$loc" ] || [ "$loc" = "claude" ]; then
        return
    fi

    ensure_cache_dir
    echo "$loc" > "$CACHE_DIR/$win_id.cache" 2>/dev/null
}

# Read location from cache for a window
# Args: window_id
read_cached_location() {
    local win_id="$1"

    if [ -f "$CACHE_DIR/$win_id.cache" ]; then
        cat "$CACHE_DIR/$win_id.cache" 2>/dev/null
    fi
}

# Clean up old cache files (older than 24 hours)
cleanup_old_cache() {
    if [ -d "$CACHE_DIR" ]; then
        find "$CACHE_DIR" -name "*.cache" -mtime +1 -delete 2>/dev/null
    fi
}

# Extract shell PID from terminal title (if present)
# Fish includes PID in format: "path [PID]" or "path: command [PID]"
extract_shell_pid_from_title() {
    local t="$1"

    # Pattern: [PID] at the end
    if echo "$t" | grep -qE '\[[0-9]+\]$'; then
        echo "$t" | grep -oP '\[(\K[0-9]+)(?=\]$)'
        return
    fi

    return 1
}

# Get working directory for footclient terminals
# Since footclient shares PID across all terminals, we have a fundamental limitation:
# We CANNOT reliably determine which shell corresponds to the focused window.
#
# This function accepts an optional shell_pid parameter (from title):
# - If shell_pid provided: use it directly (ACCURATE)
# - If no shell_pid: return NOTHING if there's ambiguity (multiple shells with children)
get_footclient_cwd() {
    local shell_pid="$1"  # Optional: specific shell PID from title

    # If caller provided a specific shell PID, use it directly
    if [ -n "$shell_pid" ]; then
        shell_cwd=$(readlink -f "/proc/$shell_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|")
        if [ -n "$shell_cwd" ] && [ "$shell_cwd" != "/" ]; then
            echo "$shell_cwd"
            return
        fi
    fi

    # No specific PID provided, try to auto-detect (with limitations)
    if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
        # Get all descendant PIDs
        all_descendants=$(pstree -p "$pid" 2>/dev/null | grep -oP '\(\K[0-9]+' | grep -v "^$pid$")

        if [ -n "$all_descendants" ]; then
            # Collect all shells and their CWDs
            shell_count=0
            shell_with_children_count=0
            last_cwd=""
            last_cwd_with_children=""

            for desc_pid in $all_descendants; do
                cmd=$(ps -p "$desc_pid" -o comm= 2>/dev/null)
                case "$cmd" in
                    fish|bash|zsh|sh)
                        shell_count=$((shell_count + 1))
                        shell_cwd=$(readlink -f "/proc/$desc_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|")

                        # Check if shell has children (command running)
                        shell_children=$(pgrep -P "$desc_pid" 2>/dev/null)

                        if [ -n "$shell_children" ]; then
                            shell_with_children_count=$((shell_with_children_count + 1))
                            last_cwd_with_children="$shell_cwd"
                        fi

                        last_cwd="$shell_cwd"
                        ;;
                esac
            done

            # If there's exactly ONE shell with children, we can confidently use its CWD
            if [ $shell_with_children_count -eq 1 ]; then
                echo "$last_cwd_with_children"
                return
            fi

            # If all shells are idle (no children) and there's only one, use it
            if [ $shell_with_children_count -eq 0 ] && [ $shell_count -eq 1 ]; then
                echo "$last_cwd"
                return
            fi

            # Multiple shells with children - we cannot determine which is focused
            # Return nothing and let the caller handle it
            return 1
        fi
    fi
}

# Extract directory from terminal title
# Handles formats: "~/path: cmd", "~/path - shell", "~ - fish", etc.
# Also removes [PID] suffix if present
extract_path_from_title() {
    local t="$1"

    # Remove [PID] suffix if present (added by fish_title for footclient detection)
    t=$(echo "$t" | sed -E 's/ \[[0-9]+\]$//')

    # Pattern 1: "~/path: anything" or "/path: anything"
    # Matches: "~/projects/foo: npm run dev - npm"
    if echo "$t" | grep -qE '^[~/][^:]*:'; then
        echo "$t" | sed -E 's/^([~/][^:]*):.*$/\1/'
        return
    fi

    # Pattern 2: "~/path - shell" or "/path - shell"
    # Matches: "~/projects/foo - fish"
    if echo "$t" | grep -qE '^[~/].* - (fish|bash|zsh|sh)$'; then
        echo "$t" | sed -E 's/^([~/].*) - (fish|bash|zsh|sh)$/\1/'
        return
    fi

    # Pattern 3: "~ - anything" or "~: anything" or just "~"
    # Matches: "~ - fish", "~: ssh server", "~"
    if echo "$t" | grep -qE '^~($|[: -])'; then
        echo "~"
        return
    fi

    # Pattern 4: "[command] ~/path" or "[command] /path"
    # Matches: "ssh ~/projects/foo", "vim /etc/config"
    if echo "$t" | grep -qE '^[a-zA-Z0-9_-]+ [~/]'; then
        echo "$t" | sed -E 's/^[a-zA-Z0-9_-]+ ([~/][^ ]*).*/\1/'
        return
    fi

    # Pattern 5: Simple path starting with ~ or / (with at least one subdirectory)
    # Matches: "~/projects/web-blindando", "/etc/nginx/sites"
    # This catches Fish idle terminals where title is just the path
    if echo "$t" | grep -qE '^[~/].*/'; then
        echo "$t"
        return
    fi

    # No path found
    return 1
}

# Extract context (command/description) from terminal title
# Also removes [PID] suffix if present
extract_context_from_title() {
    local t="$1"
    local context=""

    # Remove [PID] suffix if present (added by fish_title for footclient detection)
    t=$(echo "$t" | sed -E 's/ \[[0-9]+\]$//')

    # Pattern 1: "path: command - name"
    # Example: "~/projects/foo: npm run dev - npm"
    if echo "$t" | grep -qE ':.*-'; then
        context=$(echo "$t" | sed -E 's/^[^:]*: (.*) - .*$/\1/')
        echo "$context"
        return
    fi

    # Pattern 2: "path: command"
    # Example: "~: ssht hostinger-vps blindando"
    if echo "$t" | grep -q ':'; then
        context=$(echo "$t" | cut -d: -f2- | sed 's/^ *//')
        echo "$context"
        return
    fi

    # Pattern 3: Claude Code session
    # Example: "✳ UI/UX Bug Fixes"
    if echo "$t" | grep -qE '^✳'; then
        context=$(echo "$t" | sed 's/^✳ *//')
        echo "$context"
        return
    fi

    # Pattern 4: "path - shell"
    # Example: "~/projects/foo - fish"
    # Don't return anything (shell name is not interesting context)
    return 1
}

# Build display text
# Format: [location]: [context]
# - location: directory path OR "ssh hostname"
# - context: window title (cleaned) OR foreground command
case "$app_id" in
    *footclient*)
        # footclient shares PID across all terminals
        # Extract shell PID from title (if present) for accurate CWD detection
        shell_pid=$(extract_shell_pid_from_title "$title")

        # Try to extract location from title first (most reliable when available)
        location=$(extract_path_from_title "$title")

        # If no path in title, get CWD from process tree using shell PID
        if [ -z "$location" ]; then
            location=$(get_footclient_cwd "$shell_pid")
        fi

        # If we successfully determined location, cache it
        if [ -n "$location" ] && [ "$location" != "claude" ]; then
            cache_location "$window_id" "$location"
        fi

        # If still no location, try to read from cache
        if [ -z "$location" ]; then
            cached_loc=$(read_cached_location "$window_id")
            if [ -n "$cached_loc" ]; then
                location="$cached_loc"
            fi
        fi

        # If STILL no location, use fallback
        if [ -z "$location" ]; then
            # Check if it's a Claude Code session
            if echo "$title" | grep -qE '^✳'; then
                location="claude"
            else
                location="~"  # Conservative fallback
            fi
        fi

        # Extract context from title
        context=$(extract_context_from_title "$title")

        # Build display
        if [ -n "$context" ]; then
            display_text="$location: $context"
        else
            display_text="$location"
        fi

        # Periodic cleanup (every ~100 invocations, probabilistic)
        if [ $((RANDOM % 100)) -eq 0 ]; then
            cleanup_old_cache &
        fi
        ;;

    *terminal* | *foot* | *alacritty* | *kitty* | *ghostty*)
        # For other terminals (standalone PIDs), use existing logic
        location=""
        fg_cmd=$(get_foreground_command)

        # Check if it's an SSH session
        if echo "$fg_cmd" | grep -q '^ssh '; then
            # Extract hostname from "ssh hostname" or "ssh user@hostname"
            ssh_target=$(echo "$fg_cmd" | awk '{print $2}' | sed 's/.*@//')
            location="ssh $ssh_target"
        else
            # Not SSH, get directory path
            # Try to extract from title first
            location=$(extract_path_from_title "$title")

            # If no path in title, try /proc as fallback
            if [ -z "$location" ]; then
                location=$(get_process_cwd)
            fi
        fi

        # Step 2: Get CONTEXT (what we're doing)
        context=""

        if echo "$location" | grep -q '^ssh '; then
            # In SSH session: context comes from window title
            # (remote commands aren't visible in local process tree)
            context="$title"
        else
            # Not in SSH: check for foreground commands (vim, htop, etc)
            if [ -n "$fg_cmd" ]; then
                context="$fg_cmd"
            else
                # No foreground command, extract context from title
                context=$(extract_context_from_title "$title")
            fi
        fi

        # Step 3: Build display text
        if [ -n "$location" ] && [ -n "$context" ]; then
            display_text="$location: $context"
        elif [ -n "$location" ]; then
            display_text="$location"
        elif [ -n "$context" ]; then
            display_text="$context"
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

# Output JSON (using jq for proper escaping, -c for compact output)
jq -nc \
    --arg text "$display_text" \
    --arg tooltip "$tooltip" \
    --arg class "$css_class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
