#!/usr/bin/env bash
# leech-monitor.sh — Detects processes with sustained CPU usage over time.
#
# Uses /proc/PID/stat to compute accurate per-interval CPU% (not the ps
# since-start average). Compares each 10-minute window to detect drift.
#
# Alert conditions:
#   - CPU% in current window > ALERT_CPU_THRESHOLD for ALERT_CONSECUTIVE
#     consecutive samples → logged
#   - RSS growth > ALERT_RSS_GROWTH_MB between samples → logged
#
# Alerts are written to the daily log file (no desktop notifications).
# Logs rotate automatically — files older than LOG_RETENTION_DAYS are pruned.
#
# Logs: ~/.local/share/leech-monitor/YYYY-MM-DD.log
# State: ~/.local/share/leech-monitor/.state (last sample data)

LOG_DIR="$HOME/.local/share/leech-monitor"
STATE_FILE="$LOG_DIR/.state"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
STREAK_FILE="$LOG_DIR/.streaks"

ALERT_CPU_THRESHOLD=5       # % CPU in a 10-min window to flag a process
ALERT_CONSECUTIVE=3         # Consecutive windows above threshold before notifying
ALERT_RSS_GROWTH_MB=150     # MB RSS growth in one window to flag a memory leak
IGNORE_COMMS="kworker kthread ksoftirqd migration rcu watchdog"
LOG_RETENTION_DAYS=14   # Prune log files older than this

HZ=$(getconf CLK_TCK 2>/dev/null || echo 100)

mkdir -p "$LOG_DIR"

# Prune old log files
find "$LOG_DIR" -maxdepth 1 -name '*.log' -type f -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Read CPU jiffies for a PID from /proc
# Returns utime+stime or empty if process gone
read_jiffies() {
    local pid=$1
    local stat_file="/proc/$pid/stat"
    [[ -f "$stat_file" ]] || return 1
    # Format: pid (comm) state ppid ... utime stime ...
    # Strip everything up to and including the closing paren of comm
    local raw
    raw=$(cat "$stat_file" 2>/dev/null) || return 1
    local after_comm="${raw#*) }"
    read -ra fields <<< "$after_comm"
    # Fields after state (index 0): ppid=1, pgrp=2, ... utime=11, stime=12
    echo $(( fields[11] + fields[12] ))
}

# Read RSS in kB for a PID
read_rss_kb() {
    local pid=$1
    awk '/^VmRSS:/{print $2; exit}' "/proc/$pid/status" 2>/dev/null || echo 0
}

# Read comm for a PID
read_comm() {
    cat "/proc/$1/comm" 2>/dev/null | tr -d '\n' || echo "?"
}

# Check if comm is in ignore list
is_ignored() {
    local comm="$1"
    for ign in $IGNORE_COMMS; do
        [[ "$comm" == $ign* ]] && return 0
    done
    return 1
}

now=$(date +%s)
uptime_ticks=$(awk '{print $1}' /proc/uptime | awk -F. '{print $1}')

# Build current snapshot: pid -> jiffies,rss,comm
declare -A cur_jiffies cur_rss cur_comm

for pid_dir in /proc/[0-9]*/stat; do
    pid="${pid_dir%/stat}"
    pid="${pid#/proc/}"
    [[ -d "/proc/$pid" ]] || continue

    comm=$(read_comm "$pid")
    is_ignored "$comm" && continue

    jiffies=$(read_jiffies "$pid") || continue
    rss=$(read_rss_kb "$pid")

    cur_jiffies[$pid]=$jiffies
    cur_rss[$pid]=$rss
    cur_comm[$pid]=$comm
done

# Load previous state
declare -A prev_jiffies prev_rss prev_time

if [[ -f "$STATE_FILE" ]]; then
    while IFS='|' read -r pid jiffies rss ts; do
        prev_jiffies[$pid]=$jiffies
        prev_rss[$pid]=$rss
        prev_time[$pid]=$ts
    done < "$STATE_FILE"
fi

# Load streak counters
declare -A streaks
if [[ -f "$STREAK_FILE" ]]; then
    while IFS='|' read -r pid comm count; do
        streaks[$pid]="$comm|$count"
    done < "$STREAK_FILE"
fi

# Compare and detect
log "--- Sample ($(date '+%Y-%m-%d %H:%M')) ---"

alerts=()
declare -A new_streaks

for pid in "${!cur_jiffies[@]}"; do
    comm="${cur_comm[$pid]}"
    jiffies="${cur_jiffies[$pid]}"
    rss="${cur_rss[$pid]}"

    if [[ -n "${prev_jiffies[$pid]}" ]]; then
        prev_j="${prev_jiffies[$pid]}"
        prev_t="${prev_time[$pid]}"
        elapsed=$(( now - prev_t ))

        if (( elapsed > 0 )); then
            delta_j=$(( jiffies - prev_j ))
            # CPU% = (delta_jiffies / HZ) / elapsed_seconds * 100
            cpu_pct=$(( delta_j * 100 / (HZ * elapsed) ))

            # RSS growth
            prev_r="${prev_rss[$pid]}"
            rss_growth_mb=$(( (rss - prev_r) / 1024 ))

            # Log anything notable
            if (( cpu_pct > 1 || rss_growth_mb > 20 )); then
                log "  PID $pid ($comm): CPU=${cpu_pct}% RSS=${rss}kB growth=${rss_growth_mb}MB"
            fi

            # CPU streak tracking
            if (( cpu_pct >= ALERT_CPU_THRESHOLD )); then
                prev_streak="${streaks[$pid]}"
                prev_count="${prev_streak##*|}"
                prev_count="${prev_count:-0}"
                new_count=$(( prev_count + 1 ))
                new_streaks[$pid]="$comm|$new_count"

                if (( new_count >= ALERT_CONSECUTIVE )); then
                    alerts+=("CPU leech: $comm (PID $pid) — ${cpu_pct}% CPU for ${new_count} consecutive samples")
                fi
            else
                # Reset streak
                new_streaks[$pid]="$comm|0"
            fi

            # Memory leak alert
            if (( rss_growth_mb >= ALERT_RSS_GROWTH_MB )); then
                alerts+=("Memory growth: $comm (PID $pid) — +${rss_growth_mb}MB RSS in last window")
            fi
        fi
    fi
done

# Save new state
: > "$STATE_FILE"
for pid in "${!cur_jiffies[@]}"; do
    echo "${pid}|${cur_jiffies[$pid]}|${cur_rss[$pid]}|${now}" >> "$STATE_FILE"
done

# Save streaks
: > "$STREAK_FILE"
for pid in "${!new_streaks[@]}"; do
    echo "${pid}|${new_streaks[$pid]}" >> "$STREAK_FILE"
done

# Log alerts (no desktop notifications — review via log files)
for alert in "${alerts[@]}"; do
    log "  ALERT: $alert"
done

log "--- Done (${#cur_jiffies[@]} processes sampled) ---"
