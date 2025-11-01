#!/usr/bin/env bash
# Wrapper for USB monitor to ensure clean output

# Execute the main script and ensure only JSON output
/usr/bin/bash /home/milo/.config/sway/scripts/usb-monitor.sh 2>/dev/null
