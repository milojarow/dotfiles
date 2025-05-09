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

# Check if user canceled the dialog (by pressing Escape)
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

# Send SIGUSR1 to swayidle to force a reset
pkill -USR1 swayidle

# Notify user
notify-send "Idle timeout set" "System will lock after $timeout_minutes minutes of inactivity"
