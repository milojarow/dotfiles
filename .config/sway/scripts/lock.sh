#!/bin/bash
# ── Lock Screen & Idle ────────────────────────────────────────────────────────
# Role:     Captures screen, blurs it, launches swaylock; resets swayidle on unlock
# Files:    lock.sh · idle-timeout.sh · auto-idle-timeout.sh · secure-suspend.sh
#           ~/.config/swaylock/config           (swaylock visual config)
#           ~/.config/swayidle/config           (generated — do not edit manually)
#           ~/.config/sway/autostart            ($initialize_idle_daemon)
#           ~/.config/sway/config.d/01-definitions.conf  ($locking)
#           ~/.config/sway/modes/default        ($mod+x keybind)
#           ~/.config/sway/modes/shutdown       (l=lock, u=suspend)
#           ~/.config/waybar/config.jsonc       (idle_inhibitor module)
# Programs: swaylock  swayidle  grim  imagemagick  systemctl  notify-send  rofi
# Daemon:   swayidle (systemd user service, config at ~/.config/swayidle/config)
# Triggers: $mod+x keybind · swayidle timeout · before-sleep · shutdown menu
# ─────────────────────────────────────────────────────────────────────────────

# Robust lockfile mechanism to prevent multiple concurrent executions
LOCKFILE="/tmp/lock.sh.lock"

# Track whether swaylock actually ran so we can reset swayidle on exit.
# Without this, swayidle's stale idle timer fires again immediately after
# unlock, causing a double lock screen.
SWAYLOCK_RAN=false

# Capture swayidle state before locking: if the idle inhibitor was active
# (swayidle killed intentionally), do not restart it after unlock.
SWAYIDLE_WAS_RUNNING=false
pgrep -x swayidle > /dev/null && SWAYIDLE_WAS_RUNNING=true

_on_exit() {
    if $SWAYLOCK_RAN; then
        if $SWAYIDLE_WAS_RUNNING; then
            # Kill and immediately restart swayidle to reset idle timer after unlock.
            # Do NOT wait for swayidle to die — waiting creates a deadlock because
            # swayidle blocks waiting for lock.sh to exit while lock.sh waits for
            # swayidle to die.
            pkill -x swayidle 2>/dev/null
            swayidle -w -S seat0 200>&- &
            disown
        fi
        # Reopen eww bar after unlock: fixes width regression from resume (output
        # resolution may not have settled when eww first opened) and forces the
        # idle-inhibitor deflisten to re-emit the correct state.
        /home/milo/.config/eww/scripts/open-windows.sh &
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
LOCK_LOG="$HOME/.cache/secure-suspend.log"
echo "lock.sh: started (PREBLURRED=${SECURE_SUSPEND_PREBLURRED:-0}, swaylock_already=$(pgrep -x swaylock > /dev/null && echo yes || echo no))" >> "$LOCK_LOG"
if pgrep -x swaylock > /dev/null; then
    exit 0
fi

# Use consistent filename to overwrite previous image
SCREENSHOT="/tmp/swaylock-blur.png"

# If called from secure-suspend.sh with pre-blurred image, skip capture and blur
if [[ "${SECURE_SUSPEND_PREBLURRED:-0}" != "1" ]] || [[ ! -f "$SCREENSHOT" ]]; then
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
fi

# Lock screen with blurred background
SWAYLOCK_RAN=true
LOCK_LOG="$HOME/.cache/secure-suspend.log"
echo "lock.sh: launching swaylock -i $SCREENSHOT (PREBLURRED=${SECURE_SUSPEND_PREBLURRED:-0})" >> "$LOCK_LOG"
swaylock -i "$SCREENSHOT" 2>> "$LOCK_LOG"
echo "lock.sh: swaylock exited with code $?" >> "$LOCK_LOG"

# Cleanup after unlock
rm -f "$SCREENSHOT"
