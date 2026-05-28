#!/bin/bash
# feature: _shared
# role:    shared
# Opens all persistent eww windows at daemon startup and after resume.
#
# Concurrency control:
#   - flock on fd 9 prevents two concurrent runs (e.g. ExecStartPost racing
#     eww-resume-watch.sh) which would create duplicate layer-shell surfaces
#     for ':exclusive true' windows like bar.
#   - Acquired with a 10s timeout so we never hang forever.
#   - Every eww CLI subprocess is spawned with '9>&-' so fd 9 does NOT leak
#     into the daemon's long-lived children (deflisten subscribe scripts).
#     Without that, any hung 'eww open' CLI would keep the open file
#     description — and its lock — alive for days, permanently blocking
#     every subsequent resume recovery. This is the true root cause behind
#     "bar missing after suspend" incidents.

EWW=/home/milo/.cargo/bin/eww
LOG_TAG=eww-open-windows
RESTART_GUARD=/tmp/eww-open-windows.restart-guard

# Reap any 'eww open|close|update' CLI processes hung from prior runs. They
# hold sockets to (possibly dead) daemons and are the seed for double-bar
# orphans: a hung CLI auto-spawns a fresh daemon when its old socket is
# unresponsive, and that rogue daemon creates its own layer-shell surfaces
# that systemd's main daemon never tracks.
pkill -f "^${EWW} (open|close|update)" 2>/dev/null || true
sleep 0.2

# Verify the daemon we're about to drive actually exists before any CLI call.
# Without this guard a missed daemon causes the next 'eww open' CLI to
# auto-spawn a rogue daemon — which is what produces orphan bar surfaces.
if ! "$EWW" ping >/dev/null 2>&1; then
    logger -t "$LOG_TAG" "daemon not responding to ping, aborting"
    exit 1
fi

exec 9>/tmp/eww-open-windows.lock
if ! flock -w 10 9; then
    logger -t "$LOG_TAG" "could not acquire lock within 10s, aborting"
    exit 1
fi

WINDOWS=(
    disk-widget
    activate-linux
    sysmonitor-window
    temps-window
    usb-widget
    bt-widget
    timer-widget
    clock
    selene-storage-window
    mongo-tunnel-window
    battery-window
    tmux-sessions
    wallpaper-cycle
)

# '9>&-' closes fd 9 in the child, preventing flock inheritance leaks.
open_window() {
    "$EWW" close "$1" 2>/dev/null 9>&-
    "$EWW" open "$1" 2>/dev/null 9>&-
}

is_active() {
    "$EWW" active-windows 2>/dev/null 9>&- | grep -q "^${1}:"
}

# Phase 1: open all windows in order.
for w in "${WINDOWS[@]}"; do
    open_window "$w"
done

# Phase 2: give the daemon a moment to register the windows, then verify and
# retry anything that silently failed.
#
# IMPORTANT: bar is excluded from per-window retries. Its ':exclusive true'
# layer-shell surface can desync from eww's tracking after sway re-registers
# outputs on resume — eww forgets the surface but sway keeps rendering it.
# In that state 'eww close bar' fails ("no such window was open") and
# 'eww open bar' creates a SECOND surface, leaving the user with two
# stacked bars. So if bar is missing in Phase 2 we skip retry and let
# Phase 3 do a clean service restart, which is the only reliable way to
# clear orphan layer-shell surfaces.
sleep 0.4
for w in "${WINDOWS[@]}"; do
    [ "$w" = "bar" ] && continue
    attempts=0
    while [ "$attempts" -lt 3 ]; do
        if is_active "$w"; then
            break
        fi
        attempts=$((attempts + 1))
        logger -t "$LOG_TAG" "retry $attempts for window: $w"
        open_window "$w"
        sleep 0.3
    done
done

# Phase 3 (bar auto-restart) removed during the waybar migration: the bar moved
# to waybar, so there is no eww 'bar' window to recover anymore. The old logic
# restarted eww.service whenever 'bar' was missing — which would now loop forever.
# See bar.yuck.deprecated.
