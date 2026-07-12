#!/usr/bin/env bash
# claude-watchdog.sh — Event-driven watchdog for runaway Claude Code sessions.
# Listens to podman container create events. When container creation rate
# exceeds threshold, checks for headless claude processes and kills them.
#
# Architecture:
#   podman events (stream) → count creates in sliding window → if burst detected
#   → check pgrep for headless "claude -p" processes → kill + notify
#
# Runs as: systemd user service (long-lived, event-driven, no polling)

set -euo pipefail

# --- Configuration ---
WINDOW_SECONDS=120        # Sliding window size
CONTAINER_THRESHOLD=20    # Max container creates in window before alarm
HEADLESS_THRESHOLD=3      # Max headless claude processes before kill
COOLDOWN_SECONDS=60       # After taking action, wait before acting again

# --- State ---
declare -a TIMESTAMPS=()
LAST_ACTION=0

log() {
    echo "[$(date +%H:%M:%S)] $*"
}

# Remove timestamps older than the sliding window
prune_window() {
    local now cutoff
    now=$(date +%s)
    cutoff=$(( now - WINDOW_SECONDS ))
    local pruned=()
    for ts in "${TIMESTAMPS[@]}"; do
        if (( ts > cutoff )); then
            pruned+=("$ts")
        fi
    done
    TIMESTAMPS=("${pruned[@]+"${pruned[@]}"}")
}

# Count headless claude processes (claude -p or claude --print)
count_headless() {
    pgrep -af 'claude\s+(-p|--print)\s' 2>/dev/null | grep -cv 'pgrep' || echo 0
}

# Count all claude processes
count_all_claude() {
    pgrep -c 'claude' 2>/dev/null || echo 0
}

# Kill all headless claude processes
kill_headless() {
    local pids
    pids=$(pgrep -af 'claude\s+(-p|--print)\s' 2>/dev/null | grep -v 'pgrep' | awk '{print $1}') || true
    if [[ -n "$pids" ]]; then
        local count
        count=$(echo "$pids" | wc -l)
        log "KILLING $count headless claude processes: $pids"
        echo "$pids" | xargs -r kill -TERM 2>/dev/null || true
        # Give them 5 seconds to die gracefully, then force
        sleep 5
        echo "$pids" | xargs -r kill -KILL 2>/dev/null || true
        return 0
    fi
    return 1
}

# Send desktop notification
notify() {
    local urgency="$1" title="$2" body="$3"
    notify-send -u "$urgency" -a "Claude Watchdog" "$title" "$body" 2>/dev/null || true
}

# Main action: assess situation and respond
respond_to_burst() {
    local now
    now=$(date +%s)

    # Cooldown check
    if (( now - LAST_ACTION < COOLDOWN_SECONDS )); then
        return
    fi

    local headless total
    headless=$(count_headless)
    total=$(count_all_claude)
    local container_count=${#TIMESTAMPS[@]}

    log "BURST DETECTED: $container_count containers in ${WINDOW_SECONDS}s, $total claude procs, $headless headless"

    if (( headless >= HEADLESS_THRESHOLD )); then
        log "ACTION: Killing headless claude sessions (fork bomb pattern)"
        notify "critical" \
            "Claude Watchdog: Fork bomb detected" \
            "$headless headless sessions killed. $container_count containers in ${WINDOW_SECONDS}s."
        kill_headless
        LAST_ACTION=$now
    elif (( total > 5 )); then
        log "WARNING: High claude process count ($total) but few headless ($headless)"
        notify "normal" \
            "Claude Watchdog: Unusual activity" \
            "$total claude processes running, $container_count containers in ${WINDOW_SECONDS}s."
        LAST_ACTION=$now
    else
        log "INFO: Container burst but claude process count normal ($total). Likely legitimate."
    fi
}

# --- Main loop: listen to podman events ---
log "Watchdog started. Listening for container create events..."
log "Thresholds: $CONTAINER_THRESHOLD creates/$WINDOW_SECONDS s, $HEADLESS_THRESHOLD headless procs"

podman events --filter event=create --format '{{.Time}}' 2>/dev/null | while read -r _event_time; do
    now=$(date +%s)
    TIMESTAMPS+=("$now")
    prune_window

    if (( ${#TIMESTAMPS[@]} >= CONTAINER_THRESHOLD )); then
        respond_to_burst
    fi
done

# If podman events exits (shouldn't happen), log and exit
log "ERROR: podman events stream ended unexpectedly"
exit 1
