#!/usr/bin/env bash
# mongo-tunnel-subscribe.sh — eww deflisten for MongoDB SSH tunnel toggle.
#
# Architecture:
# - Named pipe receives toggle signals from the widget onclick
# - Emits JSON with active (bool) and status (disconnected/connecting/connected)
# - Manages SSH tunnel: ssh -fN -L 27017:localhost:27017 selene

PIPE="/tmp/eww-mongo-tunnel"
TUNNEL_PATTERN="ssh.*-L 27017:localhost:27017"

emit() {
    if pgrep -f "$TUNNEL_PATTERN" > /dev/null 2>&1; then
        printf '{"active": true, "status": "connected"}\n'
    else
        printf '{"active": false, "status": "disconnected"}\n'
    fi
}

toggle() {
    if pgrep -f "$TUNNEL_PATTERN" > /dev/null 2>&1; then
        pkill -f "$TUNNEL_PATTERN"
    else
        # Show connecting state while SSH authenticates
        printf '{"active": false, "status": "connecting"}\n'
        # -f backgrounds after auth, -N no remote command
        ssh -fN -o ConnectTimeout=10 -o BatchMode=yes \
            -L 27017:localhost:27017 selene 2>/dev/null
    fi
    emit
}

# Re-emit state when signaled externally
trap 'emit' USR1

# Recreate pipe on each (re)start
rm -f "$PIPE"
mkfifo "$PIPE"

# Bootstrap: emit current state
emit

# Block waiting for toggle signals from the widget
while read -r _ < "$PIPE"; do
    toggle
done
