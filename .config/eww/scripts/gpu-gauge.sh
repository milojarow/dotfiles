#!/bin/bash
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

# Alternate between two files so eww detects the path change and reloads the image
N=$(( ($(cat /tmp/eww-gpu-gauge-n 2>/dev/null || echo 0) + 1) % 2 ))
echo "$N" > /tmp/eww-gpu-gauge-n

OUT="/tmp/eww-gpu-gauge-${N}.png"
ICON=$(python3 -c "import sys; sys.stdout.write(chr(0xf0eb7))")
python3 ~/.config/eww/scripts/gauge-render.py "$TEMP" 0 100 "GPU" "$OUT" "°C" "$ICON" 2>/dev/null
echo "$OUT"
