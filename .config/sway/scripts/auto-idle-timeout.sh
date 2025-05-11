#!/bin/bash

# This script automatically sets swayidle timeout to 1 minute (60 seconds)
# Created to run at Sway startup

# Set timeout value (in minutes)
timeout_minutes=1

# Convert minutes to seconds
timeout_seconds=$((timeout_minutes * 60))

# Update swayidle config file
mkdir -p ~/.config/swayidle
echo "timeout $timeout_seconds /home/milo/.config/sway/scripts/lock.sh" > ~/.config/swayidle/config

# Restart swayidle to apply changes
pkill swayidle || true
swayidle -w &

