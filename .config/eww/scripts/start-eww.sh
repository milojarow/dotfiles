#!/bin/bash
# Entry point called by sway exec_always on startup and reload.
# Uses a PID file to ensure only one instance runs at a time.

export PATH="$HOME/.cargo/bin:$PATH"

PIDFILE=/tmp/start-eww.pid
TIMEOUT=10

# Kill previous instance of this script if still running
if [[ -f "$PIDFILE" ]]; then
    old_pid=$(cat "$PIDFILE")
    kill "$old_pid" 2>/dev/null
fi
echo $$ > "$PIDFILE"

# Kill existing eww daemon to ensure a clean start
eww kill 2>/dev/null

# Wait for daemon to fully stop
elapsed=0
while eww ping &>/dev/null; do
    sleep 0.1
    (( elapsed++ ))
    (( elapsed >= TIMEOUT * 10 )) && break
done

# Start fresh daemon
eww daemon

# Wait for daemon to be ready
elapsed=0
until eww ping &>/dev/null; do
    sleep 0.1
    (( elapsed++ ))
    if (( elapsed >= TIMEOUT * 10 )); then
        echo "eww daemon failed to start" >&2
        rm -f "$PIDFILE"
        exit 1
    fi
done

# Open all widgets
~/.config/eww/scripts/open-windows.sh

rm -f "$PIDFILE"
