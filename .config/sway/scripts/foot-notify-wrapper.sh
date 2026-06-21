#!/usr/bin/env bash
# ── foot notify wrapper ───────────────────────────────────────────────────────
# Role:    Wraps `fyi` (foot's [desktop-notifications] command). Tags every
#          notification with the sway con_id of the foot window that emitted it,
#          via --category=claudewin:<con_id>, so notif-dismiss-on-focus.py can
#          dismiss PER-WINDOW (only when you focus the window that generated it,
#          not any foot). foot's native click-to-focus is preserved: this execs
#          fyi, so fyi's stdout (id=/action=/xdgtoken=) flows straight to foot.
# Files:   foot-notify-wrapper.sh   (paired: notif-dismiss-on-focus.py)
# Wired:   ~/.config/foot/foot.ini  [desktop-notifications] command=
# Notes:   - Writes nothing to stdout itself; only exec'd fyi does (foot parses
#            that stdout for window activation).
#          - On any failure it still execs fyi untagged, so notifications never
#            break (click-to-focus still works, just no per-window auto-dismiss).
#          - Assumes foot normal mode (one process per window). In --server mode
#            $PPID would be the shared server and the tag would be wrong.
# ─────────────────────────────────────────────────────────────────────────────

set -u

# con_id of the nearest foot ancestor = the window that emitted this notification.
find_con_id() {
    local p=$PPID tree pid cid i
    local -a pids=()
    for ((i = 0; i < 12; i++)); do
        [[ -z $p || $p -le 1 ]] && break
        pids+=("$p")
        p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    done
    [[ ${#pids[@]} -eq 0 ]] && return 1
    tree=$(swaymsg -t get_tree 2>/dev/null) || return 1
    for pid in "${pids[@]}"; do
        cid=$(jq -r --argjson pid "$pid" \
            '.. | objects | select(.pid? == $pid) | .id' <<<"$tree" 2>/dev/null | head -1)
        if [[ -n $cid ]]; then
            printf '%s' "$cid"
            return 0
        fi
    done
    return 1
}

conid=$(find_con_id) || conid=""

if [[ -n $conid ]]; then
    exec fyi --category="claudewin:$conid" "$@"
else
    exec fyi "$@"
fi
