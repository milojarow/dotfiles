#!/bin/bash
# Kill any existing eww daemon
killall eww 2>/dev/null
# Wait a moment
sleep 0.5
# Start eww daemon
eww daemon
# Wait for daemon to initialize
sleep 1
# Open widgets
eww open cpu-dashboard
eww open cpu-temperature
