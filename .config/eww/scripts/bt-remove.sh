#!/usr/bin/env bash
eww update bt-forgetting="$1"
bluetoothctl remove "$1" 2>/dev/null
sleep 0.5
eww update bt-forgetting=""
if bluetoothctl devices Trusted 2>/dev/null | grep -qi "$1"; then
    notify-send -u critical "Bluetooth" "Failed to remove device"
fi
