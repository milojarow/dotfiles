#!/bin/bash

# Set timeout value (in minutes)
timeout_minutes=5  # Changed from 1 to 5 for a more reasonable default

# Convert minutes to seconds
timeout_seconds=$((timeout_minutes * 60))

# Update swayidle config file with a more complete configuration
mkdir -p ~/.config/swayidle
cat > ~/.config/swayidle/config << EOF
# Lock screen after timeout
timeout $timeout_seconds 'pgrep -x swaylock > /dev/null || /home/milo/.config/sway/scripts/lock.sh'

# Turn off displays after 2x timeout
timeout $(($timeout_seconds * 2)) 'swaymsg "output * power off"' resume 'swaymsg "output * power on"'

# Lock before sleep (lock.sh has internal guard against multiple instances)
before-sleep '/home/milo/.config/sway/scripts/lock.sh'

# Make sure there's only one lock when the lock command is used
lock 'pgrep -x swaylock > /dev/null || /home/milo/.config/sway/scripts/lock.sh'
EOF

# Restart swayidle to apply changes
pkill swayidle || true
swayidle -w &
