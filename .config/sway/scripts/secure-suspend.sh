#!/bin/bash
# ~/.config/sway/scripts/secure-suspend.sh
# Lock the screen first, then suspend to ensure security on resume

# Lock the screen immediately (run in background to avoid blocking)
~/.config/sway/scripts/lock.sh &

# Give lock screen time to fully initialize
sleep 2

# Now suspend the system
systemctl sleep
