#!/bin/bash
# ~/.config/sway/scripts/lid-handler.sh
# Handle lid close: turn off displays, and re-suspend if ACPI wake interrupted a suspend

# Check if the system just woke from suspend (within last 5 seconds)
# This happens when closing the lid generates an ACPI wake event during S3
LAST_RESUME=$(journalctl -b --no-pager -o short-unix -n 1 \
    --grep="System returned from sleep operation" 2>/dev/null | awk '{print int($1)}')
NOW=$(date +%s)

if [ -n "$LAST_RESUME" ] && [ $((NOW - LAST_RESUME)) -lt 5 ]; then
    # Lid close woke us from suspend — re-suspend immediately
    echo "$(date): Lid close woke system from S3, re-suspending" >> ~/.cache/lid-handler.log
    systemctl suspend
    exit 0
fi

# Check if suspend process is already running
if pgrep -f "systemd-sleep\|systemctl.*sleep" > /dev/null; then
    echo "$(date): Suspend in progress, ignoring lid close" >> ~/.cache/lid-handler.log
    exit 0
fi

# Normal lid close: just turn off displays
swaymsg "output * power off"
