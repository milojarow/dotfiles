#!/usr/bin/env bash
output=$(bluetoothctl connect "$1" 2>&1)
if ! echo "$output" | grep -qi "successful"; then
    notify-send -u critical "Bluetooth" "Connect failed"
fi
