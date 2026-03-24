#!/usr/bin/env bash
# mongo-tunnel-subscribe.sh — eww deflisten for MongoDB SSH tunnel toggle.
#
# Uses a PID file instead of pgrep -f to avoid false positives
# (pgrep -f matches its own command line).

PIPE="/tmp/eww-mongo-tunnel"
PIDFILE="/tmp/mongo-tunnel.pid"

is_alive() {
    [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

emit() {
    if is_alive; then
        printf '{"active": true, "status": "connected"}\n'
    else
        rm -f "$PIDFILE"
        printf '{"active": false, "status": "disconnected"}\n'
    fi
}

toggle() {
    if is_alive; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    else
        printf '{"active": false, "status": "connecting"}\n'
        if ssh -fN -o ConnectTimeout=10 -o BatchMode=yes \
               -L 27017:localhost:27017 selene 2>/dev/null; then
            # ssh -f returns after forking; find the backgrounded process
            pgrep -n -f "ssh.*27017:localhost:27017.*selene" > "$PIDFILE" 2>/dev/null
        fi
    fi
    emit
}

trap 'emit' USR1

rm -f "$PIPE"
mkfifo "$PIPE"

emit

while read -r _ < "$PIPE"; do
    toggle
done
