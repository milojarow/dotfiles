#!/usr/bin/env bash
trap 'eww update bt-connecting=""' EXIT
eww update bt-connecting="$1"
output=$(bluetoothctl disconnect "$1" 2>&1)
if ! echo "$output" | grep -qi "successful"; then
    notify-send -u critical "Bluetooth" "Disconnect failed"
fi
