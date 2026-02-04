#!/bin/bash
# ~/.config/sway/scripts/lid-handler.sh
# Turn off displays when lid is closed (no suspend, processes keep running)

# Check if suspend process is already running
if pgrep -f "systemd-sleep\|systemctl.*sleep" > /dev/null; then
    echo "Suspend in progress, ignoring lid close" >> ~/.cache/lid-handler.log
    exit 0
fi

# Turn off all displays
swaymsg "output * power off"
