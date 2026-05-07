#!/bin/bash
# Opens all persistent eww windows at daemon startup and after resume.
#
# Concurrency control:
#   - flock on fd 9 prevents two concurrent runs (e.g. ExecStartPost racing
#     eww-resume-watch.sh) which would create duplicate layer-shell surfaces
#     for ':exclusive true' windows like eww-bar.
#   - Acquired with a 10s timeout so we never hang forever.
#   - Every eww CLI subprocess is spawned with '9>&-' so fd 9 does NOT leak
#     into the daemon's long-lived children (deflisten subscribe scripts).
#     Without that, any hung 'eww open' CLI would keep the open file
#     description — and its lock — alive for days, permanently blocking
#     every subsequent resume recovery. This is the true root cause behind
#     "eww-bar missing after suspend" incidents.

exec 9>/tmp/eww-open-windows.lock
if ! flock -w 10 9; then
    logger -t eww-open-windows "could not acquire lock within 10s, aborting"
    exit 1
fi

EWW=/home/milo/.cargo/bin/eww
LOG_TAG=eww-open-windows
RESTART_GUARD=/tmp/eww-open-windows.restart-guard

WINDOWS=(
    eww-bar
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
    gamma-popup
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
# IMPORTANT: eww-bar is excluded from per-window retries. Its ':exclusive true'
# layer-shell surface can desync from eww's tracking after sway re-registers
# outputs on resume — eww forgets the surface but sway keeps rendering it.
# In that state 'eww close eww-bar' fails ("no such window was open") and
# 'eww open eww-bar' creates a SECOND surface, leaving the user with two
# stacked bars. So if eww-bar is missing in Phase 2 we skip retry and let
# Phase 3 do a clean service restart, which is the only reliable way to
# clear orphan layer-shell surfaces.
sleep 0.4
for w in "${WINDOWS[@]}"; do
    [ "$w" = "eww-bar" ] && continue
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

# Phase 3: last-resort recovery for eww-bar. If the exclusive bar still isn't
# alive after retries, restart the whole service — ExecStartPost re-runs this
# script against a fresh daemon, which resolves stale layer-shell state.
# A guard file prevents infinite restart loops when something structural is
# broken: only restart if we haven't already done so in the last 60 seconds.
# flock must be released before 'systemctl restart' or ExecStartPost (which
# re-invokes this script) would deadlock waiting for the lock we still hold.
if ! is_active eww-bar; then
    now=$(date +%s)
    last_restart=0
    [ -f "$RESTART_GUARD" ] && last_restart=$(cat "$RESTART_GUARD" 2>/dev/null || echo 0)
    if [ $((now - last_restart)) -gt 60 ]; then
        logger -t "$LOG_TAG" "eww-bar missing after retries; restarting eww.service"
        echo "$now" > "$RESTART_GUARD"
        flock -u 9
        exec 9>&-
        systemctl --user --no-block restart eww.service
    else
        logger -t "$LOG_TAG" "eww-bar still missing but restart guard is active; giving up"
    fi
fi
