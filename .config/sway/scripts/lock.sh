#!/bin/bash

# Robust lockfile mechanism to prevent multiple concurrent executions
LOCKFILE="/tmp/lock.sh.lock"

# Track whether swaylock actually ran so we can reset swayidle on exit.
# Without this, swayidle's stale idle timer fires again immediately after
# unlock, causing a double lock screen.
SWAYLOCK_RAN=false

_on_exit() {
    if $SWAYLOCK_RAN; then
        # Reset swayidle idle timer after unlock to prevent immediate re-lock
        pkill -x swayidle 2>/dev/null
        while pgrep -x swayidle > /dev/null 2>&1; do sleep 0.05; done
        swayidle -w -S seat0 &
        disown
    fi
}
trap _on_exit EXIT

# Attempt to acquire lock with timeout
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    # Another instance is running, exit silently
    exit 0
fi

# Prevent multiple lock instances - if swaylock is already running, exit
if pgrep -x swaylock > /dev/null; then
    exit 0
fi

# Use consistent filename to overwrite previous image
SCREENSHOT="/tmp/swaylock-blur.png"

# Capture the screen (fallback to solid color lock if grim fails)
if ! grim "$SCREENSHOT" 2>/dev/null; then
    SWAYLOCK_RAN=true
    swaylock -c 282a36
    exit 0
fi

# Apply blur - reduced from 0x15 to 0x8 to stay within InhibitDelayMaxSec
if command -v magick &> /dev/null; then
    magick "$SCREENSHOT" -blur 0x8 "$SCREENSHOT" 2>/dev/null
else
    convert "$SCREENSHOT" -blur 0x8 "$SCREENSHOT" 2>/dev/null
fi

# Fallback to solid color if blur failed
if [ ! -f "$SCREENSHOT" ]; then
    SWAYLOCK_RAN=true
    swaylock -c 282a36
    exit 0
fi

# Lock screen with blurred background
SWAYLOCK_RAN=true
swaylock -i "$SCREENSHOT"

# Cleanup after unlock
rm -f "$SCREENSHOT"
