#!/bin/bash
# ~/.config/sway/scripts/secure-suspend.sh
# Lock screen, then suspend.
# Keyboard backlight is handled by /usr/lib/systemd/system-sleep/kbd-backlight

# Lock screen FIRST so grim captures before lid might close
~/.config/sway/scripts/lock.sh &

# Wait for swaylock to actually start (means screenshot is done)
for i in $(seq 1 50); do
    pgrep -x swaylock > /dev/null && break
    sleep 0.1
done

# Suspend - screen is already locked, safe to close lid anytime
systemctl suspend
