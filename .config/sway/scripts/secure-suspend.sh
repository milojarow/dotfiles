#!/bin/bash
# ── Lock Screen & Idle ────────────────────────────────────────────────────────
# Role:     Locks screen before suspending so screenshot is taken while monitor is on
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

# Prevent double-execution: if already suspending, exit silently
LOCKFILE="/tmp/secure-suspend.lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    exit 0
fi

# Lock screen FIRST so grim captures before lid might close
~/.config/sway/scripts/lock.sh &

# Wait for swaylock to actually start (means screenshot is done)
for i in $(seq 1 50); do
    pgrep -x swaylock > /dev/null && break
    sleep 0.1
done

# Suspend - screen is already locked, safe to close lid anytime
systemctl suspend
