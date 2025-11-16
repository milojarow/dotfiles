#!/bin/bash
# ~/.config/sway/scripts/secure-suspend.sh
# Lock the screen first, then suspend to ensure security on resume

# Lock the screen immediately (lock.sh has internal guard against multiple instances)
~/.config/sway/scripts/lock.sh &

# Give lock screen time to fully initialize
sleep 2

# Now suspend the system
systemctl sleep
