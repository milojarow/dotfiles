#!/bin/bash
# ~/.config/sway/scripts/lid-handler.sh
# Smart lid handler that doesn't interfere with suspend-in-progress

# Check if suspend process is already running
if pgrep -f "systemd-sleep\|systemctl.*sleep" > /dev/null; then
    # Suspend is in progress - do nothing to avoid interference
    echo "Suspend in progress, ignoring lid close" >> ~/.cache/lid-handler.log
    exit 0
fi

# Check if we're already in a suspend/sleep state by looking at system state
if [ -f /sys/power/state ] && grep -q "mem" /sys/power/state; then
    # Check if any sleep-related systemd units are active
    if systemctl is-active --quiet systemd-suspend.service || \
       systemctl is-active --quiet systemd-sleep.service; then
        echo "System sleep service active, ignoring lid close" >> ~/.cache/lid-handler.log
        exit 0
    fi
fi

# Normal operation - lock the screen as usual
~/.config/sway/scripts/lock.sh
