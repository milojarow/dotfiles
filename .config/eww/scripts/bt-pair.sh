#!/usr/bin/env bash
# Pair and trust a device. Works for "Just Works" devices (headphones, speakers).
# Devices requiring PIN confirmation will fail silently — use bluetuith for those.
pair_output=$(bluetoothctl pair "$1" 2>&1)
if ! echo "$pair_output" | grep -qi "successful\|already paired"; then
    notify-send -u critical "Bluetooth" "Pair failed: $pair_output"
    exit 1
fi
bluetoothctl trust "$1" 2>/dev/null
