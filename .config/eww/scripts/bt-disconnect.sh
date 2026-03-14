#!/usr/bin/env bash
eww update bt-connecting="$1"
output=$(bluetoothctl disconnect "$1" 2>&1)
eww update bt-connecting=""
if ! echo "$output" | grep -qi "successful"; then
    notify-send -u critical "Bluetooth" "Disconnect failed"
fi
