#!/bin/bash
TEMP=$(sensors -j | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(int(d['coretemp-isa-0000']['Package id 0']['temp1_input']))
")

# Alternate between two files so eww detects the path change and reloads the image
N=$(( ($(cat /tmp/eww-cpu-gauge-n 2>/dev/null || echo 0) + 1) % 2 ))
echo "$N" > /tmp/eww-cpu-gauge-n

OUT="/tmp/eww-cpu-gauge-${N}.png"
python3 ~/.config/eww/scripts/gauge-render.py "$TEMP" 0 100 "CPU" "$OUT" 2>/dev/null
echo "$OUT"
