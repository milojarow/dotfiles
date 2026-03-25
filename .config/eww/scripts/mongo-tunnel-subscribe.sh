#!/usr/bin/env bash
# mongo-tunnel-subscribe.sh — eww deflisten for MongoDB SSH tunnel toggle.
#
# Bulletproof: survives eww reload, daemon restart, suspend/resume, reboots.
# Desired state persists in ~/.local/state/mongo-tunnel/wanted.
# Health check every 30s auto-reconnects if tunnel drops.

PIPE="/tmp/eww-mongo-tunnel"
PIDFILE="/tmp/mongo-tunnel.pid"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mongo-tunnel"
WANTED="$STATE_DIR/wanted"

mkdir -p "$STATE_DIR"

is_alive() {
    if [[ -f "$PIDFILE" ]]; then
        kill -0 "$(cat "$PIDFILE")" 2>/dev/null && return 0
        rm -f "$PIDFILE"
    fi
    # Fallback: find by pattern if PID file was lost
    local pid
    pid=$(pgrep -n -f "[s]sh.*-L 27017:localhost:27017.*selene" 2>/dev/null) || return 1
    echo "$pid" > "$PIDFILE"
    return 0
}

emit() {
    if is_alive; then
        printf '{"active": true, "status": "connected"}\n'
    else
        rm -f "$PIDFILE"
        printf '{"active": false, "status": "disconnected"}\n'
    fi
}

start_tunnel() {
    printf '{"active": false, "status": "connecting"}\n'
    if ssh -fN -o ConnectTimeout=10 -o BatchMode=yes \
           -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
           -o ExitOnForwardFailure=yes \
           -L 27017:localhost:27017 selene 2>/dev/null; then
        pgrep -n -f "[s]sh.*-L 27017:localhost:27017.*selene" > "$PIDFILE" 2>/dev/null
    fi
}

toggle() {
    if is_alive; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE" "$WANTED"
    else
        touch "$WANTED"
        start_tunnel
    fi
    emit
}

# ── Startup ──────────────────────────────────────────────────────────────────
rm -f "$PIPE"
mkfifo "$PIPE"

# Reconcile: if tunnel was wanted but died, restart it
if [[ -f "$WANTED" ]] && ! is_alive; then
    start_tunnel
fi
emit

# ── Main loop ────────────────────────────────────────────────────────────────
exec 3<>"$PIPE"
while true; do
    if read -t 30 -r _ <&3; then
        toggle
    else
        # Health check: reconnect if wanted but dead
        if [[ -f "$WANTED" ]] && ! is_alive; then
            start_tunnel
            emit
        fi
    fi
done
