#!/usr/bin/env bash
# mongo-tunnel-subscribe.sh — eww deflisten for MongoDB SSH tunnel toggle.
#
# Manages two tunnels as a single unit:
#   T1: 27017 → selene (localhost:27017)
#   T2: 27018 → selene (endymion@selene, 127.0.0.1:27018)
#
# Bulletproof: survives eww reload, daemon restart, suspend/resume, reboots.
# Desired state persists in ~/.local/state/mongo-tunnel/wanted.
# Health check every 30s auto-reconnects dropped tunnels individually.

PIPE="/tmp/eww-mongo-tunnel"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mongo-tunnel"
WANTED="$STATE_DIR/wanted"

PIDFILE1="/tmp/mongo-tunnel-27017.pid"
PIDFILE2="/tmp/mongo-tunnel-27018.pid"
T1_PATTERN="[s]sh.*-L 27017:localhost:27017.*selene"
T2_PATTERN="[s]sh.*-L 27018:127.0.0.1:27018.*endymion@selene"

mkdir -p "$STATE_DIR"

SSH_OPTS=(-fN -o ConnectTimeout=10 -o BatchMode=yes \
          -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
          -o ExitOnForwardFailure=yes)

is_alive_tunnel() {
    local pidfile="$1" pattern="$2"
    if [[ -f "$pidfile" ]]; then
        kill -0 "$(cat "$pidfile")" 2>/dev/null && return 0
        rm -f "$pidfile"
    fi
    local pid
    pid=$(pgrep -n -f "$pattern" 2>/dev/null) || return 1
    echo "$pid" > "$pidfile"
    return 0
}

both_alive() {
    is_alive_tunnel "$PIDFILE1" "$T1_PATTERN" && \
    is_alive_tunnel "$PIDFILE2" "$T2_PATTERN"
}

any_alive() {
    is_alive_tunnel "$PIDFILE1" "$T1_PATTERN" || \
    is_alive_tunnel "$PIDFILE2" "$T2_PATTERN"
}

emit() {
    if both_alive; then
        printf '{"active": true, "status": "connected"}\n'
    elif any_alive; then
        printf '{"active": true, "status": "partial"}\n'
    else
        rm -f "$PIDFILE1" "$PIDFILE2"
        printf '{"active": false, "status": "disconnected"}\n'
    fi
}

start_tunnel() {
    printf '{"active": false, "status": "connecting"}\n'

    if ! is_alive_tunnel "$PIDFILE1" "$T1_PATTERN"; then
        ssh "${SSH_OPTS[@]}" -L 27017:localhost:27017 selene 2>/dev/null
        sleep 0.5
        pgrep -n -f "$T1_PATTERN" > "$PIDFILE1" 2>/dev/null
    fi

    if ! is_alive_tunnel "$PIDFILE2" "$T2_PATTERN"; then
        ssh "${SSH_OPTS[@]}" -L 27018:127.0.0.1:27018 endymion@selene 2>/dev/null
        sleep 0.5
        pgrep -n -f "$T2_PATTERN" > "$PIDFILE2" 2>/dev/null
    fi
}

kill_tunnel() {
    local pidfile="$1"
    [[ -f "$pidfile" ]] && kill "$(cat "$pidfile")" 2>/dev/null
    rm -f "$pidfile"
}

toggle() {
    if any_alive; then
        kill_tunnel "$PIDFILE1"
        kill_tunnel "$PIDFILE2"
        rm -f "$WANTED"
    else
        touch "$WANTED"
        start_tunnel
    fi
    emit
}

# ── Startup ──────────────────────────────────────────────────────────────────
rm -f "$PIPE"
mkfifo "$PIPE"

# Reconcile: if tunnels were wanted but died, restart them
if [[ -f "$WANTED" ]] && ! both_alive; then
    start_tunnel
fi
emit

# ── Main loop ────────────────────────────────────────────────────────────────
exec 3<>"$PIPE"
while true; do
    if read -t 30 -r _ <&3; then
        toggle
    else
        # Health check: reconnect individually if wanted but dead
        if [[ -f "$WANTED" ]] && ! both_alive; then
            start_tunnel
            emit
        fi
    fi
done
