#!/bin/bash
# ~/.config/sway/scripts/secure-suspend.sh
# Lock screen, turn off keyboard backlight, then suspend

KBD_DEV="dell::kbd_backlight"

# Lock screen FIRST so grim captures before lid might close
~/.config/sway/scripts/lock.sh &

# Wait for swaylock to actually start (means screenshot is done)
for i in $(seq 1 50); do
    pgrep -x swaylock > /dev/null && break
    sleep 0.1
done

# Save and turn off keyboard backlight
SAVED=$(brightnessctl --device="$KBD_DEV" get)
brightnessctl --device="$KBD_DEV" set 0 --quiet

# Suspend - screen is already locked, safe to close lid anytime
systemctl suspend

# Restore keyboard backlight after resume
brightnessctl --device="$KBD_DEV" set "$SAVED" --quiet
