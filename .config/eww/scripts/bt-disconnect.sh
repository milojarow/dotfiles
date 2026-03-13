#!/usr/bin/env bash
output=$(bluetoothctl disconnect "$1" 2>&1)
if ! echo "$output" | grep -qi "successful"; then
    notify-send -u critical "Bluetooth" "Disconnect failed"
fi
