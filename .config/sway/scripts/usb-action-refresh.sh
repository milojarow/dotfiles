#!/bin/bash
# Refresh USB module display

# Signal waybar to update
pkill -RTMIN+15 waybar

# Show notification
notify-send -u low "USB Manager" "Refreshed USB status"
