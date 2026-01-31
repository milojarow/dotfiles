#!/usr/bin/env bash
# Window title watcher and processor for waybar
# Subscribes to sway IPC events, extracts window info directly from events,
# processes titles using shell builtins, and caches results for waybar.
#
# Architecture:
#   Sway events → persistent jq process → shell builtin processing → atomic cache write → signal waybar
#   Zero redundant swaymsg queries. One persistent jq process for the script lifetime.
#   All string extraction uses case/parameter expansion (no grep/sed).

CACHE_FILE="/tmp/waybar-window-title-$USER.json"
CACHE_TMP="${CACHE_FILE}.tmp"
LOC_CACHE_DIR="/tmp/waybar-window-locations-$USER"

# --- JSON output and signaling ---
# Uses printf with manual escaping to avoid spawning jq per event

json_escape() {
    _escaped="$1"
    _escaped="${_escaped//\\/\\\\}"
    _escaped="${_escaped//\"/\\\"}"
    _escaped="${_escaped//$'\n'/\\n}"
    _escaped="${_escaped//$'\t'/\\t}"
}

output_and_signal() {
    local text="$1" tooltip="$2" css_class="$3"
    json_escape "$text"; local jtext="$_escaped"
    json_escape "$tooltip"; local jtooltip="$_escaped"
    json_escape "$css_class"; local jclass="$_escaped"
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$jtext" "$jtooltip" "$jclass" \
        > "$CACHE_TMP" && mv "$CACHE_TMP" "$CACHE_FILE"
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

# --- Shell builtin string extraction (zero subprocesses) ---

# Parse [PID] suffix from title
# Sets globals: _shell_pid, _clean_title
parse_title_pid() {
    local t="$1"
    _shell_pid=""
    case "$t" in
        *" ["[0-9]*"]")
            _shell_pid="${t##*\[}"
            _shell_pid="${_shell_pid%]}"
            _clean_title="${t% \[*}"
            ;;
        *)
            _clean_title="$t"
            ;;
    esac
}

# Extract directory path from title
# Sets global: _path
extract_path() {
    _path=""
    local t="$1"
    case "$t" in
        [~/]*:*)
            _path="${t%%:*}"
            ;;
        [~/]*" - fish"|[~/]*" - bash"|[~/]*" - zsh"|[~/]*" - sh")
            _path="${t% - *}"
            ;;
        "~"|"~ "*|"~:"*)
            _path="~"
            ;;
        [~/]*/*)
            _path="$t"
            ;;
    esac
}

# Extract context (command/description) from title
# Sets global: _context
extract_context() {
    _context=""
    local t="$1"
    case "$t" in
        *": "*" - "*)
            # "path: command - name" → extract between ": " and last " - "
            local after="${t#*: }"
            _context="${after% - *}"
            ;;
        *": "*)
            # "path: command" → extract after ": "
            _context="${t#*: }"
            ;;
        "✳ "*)
            _context="${t#✳ }"
            ;;
    esac
}

# Truncate display text if > 60 chars
# Sets global: _display
truncate_display() {
    _display="$1"
    [ ${#_display} -le 60 ] && return
    case "$_display" in
        *:*)
            local pp="${_display%%:*}"
            local cp="${_display#*: }"
            if [ ${#pp} -lt 40 ]; then
                _display="${pp}: ${cp:0:17}..."
            else
                _display="...${pp: -50}:..."
            fi
            ;;
        *)
            _display="${_display:0:57}..."
            ;;
    esac
}

# Determine CSS class from app_id
# Sets global: _css_class
get_css_class() {
    case "$1" in
        *footclient*|*terminal*|*foot*|*alacritty*|*kitty*|*ghostty*)
            _css_class="window-title terminal" ;;
        *firefox*|*chromium*|*chrome*|*brave*)
            _css_class="window-title browser" ;;
        *code*|*vim*|*nvim*|*helix*)
            _css_class="window-title editor" ;;
        *)
            _css_class="window-title" ;;
    esac
}

# --- Process tree inspection (fallback, spawns external commands) ---
# Only called when title-based extraction fails

get_foreground_command() {
    local term_pid="$1"
    [ "$term_pid" = "0" ] || [ "$term_pid" = "null" ] && return

    local children child_pid cmd shell_children
    children=$(pgrep -P "$term_pid" 2>/dev/null) || return

    for child_pid in $children; do
        cmd=$(ps -p "$child_pid" -o comm= 2>/dev/null) || continue
        case "$cmd" in
            fish|bash|zsh|sh)
                shell_children=$(pgrep -P "$child_pid" -a 2>/dev/null) || continue
                if [ -n "$shell_children" ]; then
                    echo "$shell_children" | head -1 | awk '{$1=""; print $0}' | sed 's/^ //'
                    return
                fi
                ;;
        esac
    done
}

get_footclient_cwd() {
    local spid="$1" term_pid="$2"

    if [ -n "$spid" ]; then
        local cwd
        cwd=$(readlink -f "/proc/$spid/cwd" 2>/dev/null) || true
        if [ -n "$cwd" ] && [ "$cwd" != "/" ]; then
            printf '%s' "${cwd/#$HOME/\~}"
            return
        fi
    fi

    [ "$term_pid" = "0" ] || [ "$term_pid" = "null" ] && return

    local all_desc desc_pid cmd shell_cwd shell_children
    local shell_count=0 shells_with_children=0 last_cwd="" last_cwd_children=""

    all_desc=$(pstree -p "$term_pid" 2>/dev/null | grep -oP '\(\K[0-9]+' | grep -v "^${term_pid}$") || return

    for desc_pid in $all_desc; do
        cmd=$(ps -p "$desc_pid" -o comm= 2>/dev/null) || continue
        case "$cmd" in
            fish|bash|zsh|sh)
                shell_count=$((shell_count + 1))
                shell_cwd=$(readlink -f "/proc/$desc_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|") || continue
                shell_children=$(pgrep -P "$desc_pid" 2>/dev/null)
                if [ -n "$shell_children" ]; then
                    shells_with_children=$((shells_with_children + 1))
                    last_cwd_children="$shell_cwd"
                fi
                last_cwd="$shell_cwd"
                ;;
        esac
    done

    [ $shells_with_children -eq 1 ] && printf '%s' "$last_cwd_children" && return
    [ $shells_with_children -eq 0 ] && [ $shell_count -eq 1 ] && printf '%s' "$last_cwd" && return
}

get_process_cwd() {
    local term_pid="$1"
    [ "$term_pid" = "0" ] || [ "$term_pid" = "null" ] && return

    local all_desc desc_pid cmd shell_cwd shell_children best_cwd=""
    all_desc=$(pstree -p "$term_pid" 2>/dev/null | grep -oP '\(\K[0-9]+' | grep -v "^${term_pid}$") || true

    for desc_pid in $all_desc; do
        cmd=$(ps -p "$desc_pid" -o comm= 2>/dev/null) || continue
        case "$cmd" in
            fish|bash|zsh|sh)
                shell_children=$(pgrep -P "$desc_pid" 2>/dev/null)
                shell_cwd=""
                [ -r "/proc/$desc_pid/environ" ] && \
                    shell_cwd=$(tr '\0' '\n' < "/proc/$desc_pid/environ" 2>/dev/null | grep '^PWD=' | cut -d= -f2- | sed "s|^$HOME|~|")
                [ -z "$shell_cwd" ] && \
                    shell_cwd=$(readlink -f "/proc/$desc_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|")

                if [ -z "$shell_children" ] && [ -n "$shell_cwd" ]; then
                    printf '%s' "$shell_cwd"
                    return
                elif [ -z "$best_cwd" ] && [ -n "$shell_cwd" ]; then
                    best_cwd="$shell_cwd"
                fi
                ;;
        esac
    done

    [ -n "$best_cwd" ] && printf '%s' "$best_cwd" && return
    [ -d "/proc/$term_pid" ] && readlink -f "/proc/$term_pid/cwd" 2>/dev/null | sed "s|^$HOME|~|"
}

# --- Location cache ---

cache_location() {
    local win_id="$1" loc="$2"
    [ -z "$loc" ] || [ "$loc" = "claude" ] && return
    mkdir -p "$LOC_CACHE_DIR" 2>/dev/null
    printf '%s' "$loc" > "$LOC_CACHE_DIR/$win_id.cache" 2>/dev/null
}

read_cached_location() {
    local win_id="$1"
    [ -f "$LOC_CACHE_DIR/$win_id.cache" ] && cat "$LOC_CACHE_DIR/$win_id.cache" 2>/dev/null
}

cleanup_old_cache() {
    [ -d "$LOC_CACHE_DIR" ] && find "$LOC_CACHE_DIR" -name "*.cache" -mtime +1 -delete 2>/dev/null
}

# --- Main window processing ---

process_window() {
    local window_id="$1" title="$2" app_id="$3" wclass="$4" wpid="$5"

    if [ -z "$title" ] || [ "$title" = "null" ]; then
        output_and_signal "" "No focused window" "empty"
        return
    fi

    local location="" context="" display_text=""
    local app_name="${app_id:-$wclass}"

    get_css_class "$app_id"

    case "$app_id" in
        *footclient*)
            parse_title_pid "$title"

            # Location from title (zero subprocesses)
            extract_path "$_clean_title"
            location="$_path"

            # Fallback: process tree (spawns external commands)
            [ -z "$location" ] && location=$(get_footclient_cwd "$_shell_pid" "$wpid")

            # Cache successful location
            [ -n "$location" ] && [ "$location" != "claude" ] && cache_location "$window_id" "$location"

            # Fallback: read from cache
            [ -z "$location" ] && location=$(read_cached_location "$window_id")

            # Fallback: detect Claude or default to ~
            if [ -z "$location" ]; then
                case "$title" in
                    "✳"*) location="claude" ;;
                    *) location="~" ;;
                esac
            fi

            # Context from title (zero subprocesses)
            extract_context "$_clean_title"
            context="$_context"

            if [ -n "$context" ]; then
                display_text="$location: $context"
            else
                display_text="$location"
            fi

            # Periodic cache cleanup
            [ $((RANDOM % 100)) -eq 0 ] && cleanup_old_cache &
            ;;

        *terminal*|*foot*|*alacritty*|*kitty*|*ghostty*)
            parse_title_pid "$title"
            local fg_cmd
            fg_cmd=$(get_foreground_command "$wpid")

            # Determine location
            case "$fg_cmd" in
                "ssh "*)
                    local ssh_target="${fg_cmd#ssh }"
                    ssh_target="${ssh_target%% *}"
                    ssh_target="${ssh_target##*@}"
                    location="ssh $ssh_target"
                    ;;
                *)
                    extract_path "$_clean_title"
                    location="$_path"
                    [ -z "$location" ] && location=$(get_process_cwd "$wpid")
                    ;;
            esac

            # Determine context
            case "$location" in
                "ssh "*)
                    context="$title"
                    ;;
                *)
                    if [ -n "$fg_cmd" ]; then
                        context="$fg_cmd"
                    else
                        extract_context "$_clean_title"
                        context="$_context"
                    fi
                    ;;
            esac

            # Build display
            if [ -n "$location" ] && [ -n "$context" ]; then
                display_text="$location: $context"
            elif [ -n "$location" ]; then
                display_text="$location"
            elif [ -n "$context" ]; then
                display_text="$context"
            else
                display_text="$title"
            fi
            ;;

        *)
            display_text="$title"
            ;;
    esac

    # Truncate
    truncate_display "$display_text"

    # Tooltip
    local tooltip
    if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
        tooltip="${app_name}\\n${title}"
    else
        tooltip="$title"
    fi

    output_and_signal "$_display" "$tooltip" "$_css_class"
}

# --- Bootstrap: get initial state (one-time swaymsg call) ---

bootstrap() {
    local info
    info=$(swaymsg -t get_tree | jq -r '
        [.. | select(.focused? == true and .pid?)] | first // empty |
        [(.id|tostring), (.name // ""), (.app_id // ""), (.window_properties.class // ""), (.pid|tostring)] | @tsv
    ')

    if [ -n "$info" ]; then
        IFS=$'\t' read -r wid wname wapp wclass wpid <<< "$info"
        process_window "$wid" "$wname" "$wapp" "$wclass" "$wpid"
    else
        output_and_signal "" "No focused window" "empty"
    fi
}

# --- Main event loop ---
# Single persistent jq process parses all events (no per-event jq spawning)

bootstrap

while read -r line; do
    case "$line" in
        SKIP) continue ;;
        EMPTY) output_and_signal "" "No focused window" "empty" ;;
        *)
            IFS=$'\t' read -r wid wname wapp wclass wpid <<< "$line"
            process_window "$wid" "$wname" "$wapp" "$wclass" "$wpid"
            ;;
    esac
done < <(swaymsg -t subscribe -m '["window","workspace"]' | jq --unbuffered -r '
    if .container then
        if (.change == "focus" or .change == "title") then
            [(.container.id|tostring), (.container.name // ""), (.container.app_id // ""), (.container.window_properties.class // ""), (.container.pid|tostring)] | @tsv
        else "SKIP" end
    elif .current then
        if .change == "focus" then
            if (.current.focus | length) > 0 then "SKIP"
            else "EMPTY" end
        else "SKIP" end
    else "SKIP" end
')
