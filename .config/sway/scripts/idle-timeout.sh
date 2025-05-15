#!/bin/bash

# Use rofi in dmenu mode to get timeout input with custom theme
timeout_minutes=$(rofi -dmenu \
                      -theme-str 'window {width: 400px;}' \
                      -theme-str 'entry {min-width: 100px;}' \
                      -theme-str 'inputbar {padding: 12px;}' \
                      -theme-str 'listview {lines: 0;}' \
                      -p "Idle timeout (minutes):" \
                      -mesg "Press Enter to confirm or Escape to cancel" \
                      -filter "5")

# Check if user canceled the dialog
if [ -z "$timeout_minutes" ]; then
    exit 0
fi

# Validate input is a number
if ! [[ "$timeout_minutes" =~ ^[0-9]+$ ]]; then
    notify-send "Invalid input" "Please enter a valid number"
    exit 1
fi

# Convert minutes to seconds
timeout_seconds=$((timeout_minutes * 60))

# Update config file - this keeps the other settings but updates the timeout
cat > ~/.config/swayidle/config << EOF
# Lock screen after timeout
timeout $timeout_seconds 'pgrep -x swaylock > /dev/null || /home/milo/.config/sway/scripts/lock.sh'

# Turn off displays after 2x timeout
timeout $(($timeout_seconds * 2)) 'swaymsg "output * power off"' resume 'swaymsg "output * power on"'

# Lock before sleep
before-sleep '/home/milo/.config/sway/scripts/lock.sh'

# Make sure there's only one lock when the lock command is used
lock 'pgrep -x swaylock > /dev/null || /home/milo/.config/sway/scripts/lock.sh'
EOF

# Restart swayidle to apply changes
pkill swayidle || true
swayidle -w &

# Notify user
notify-send "Idle timeout set" "System will lock after $timeout_minutes minutes of inactivity"
