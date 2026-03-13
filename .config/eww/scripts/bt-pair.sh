#!/usr/bin/env bash
# Pair and trust a device. Works for "Just Works" devices (headphones, speakers).
# Devices requiring PIN confirmation will fail silently — use bluetuith for those.
bluetoothctl pair "$1" 2>/dev/null
bluetoothctl trust "$1" 2>/dev/null
