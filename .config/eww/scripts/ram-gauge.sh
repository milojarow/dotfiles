#!/bin/bash
PCT=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf "%d", (total-avail)/total*100}' /proc/meminfo)

N=$(( ($(cat /tmp/eww-ram-gauge-n 2>/dev/null || echo 0) + 1) % 2 ))
echo "$N" > /tmp/eww-ram-gauge-n

OUT="/tmp/eww-ram-gauge-${N}.png"
python3 ~/.config/eww/scripts/gauge-render.py "$PCT" 0 100 "RAM" "$OUT" 2>/dev/null
echo "$OUT"
