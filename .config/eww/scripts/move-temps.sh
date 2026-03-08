#!/bin/bash
# move-temps.sh <axis> <delta>
# axis: x | y
# delta: integer (positive or negative pixels)
#
# Reads current x/y from temps.yuck, applies delta, writes back, reloads eww.

YUCK="$HOME/.config/eww/widgets/temps.yuck"
AXIS="$1"
DELTA="$2"

if [[ "$AXIS" == "x" ]]; then
    CURRENT=$(grep -oP '(?<=:x ")\d+(?=px")' "$YUCK")
    NEW=$(( CURRENT + DELTA ))
    sed -i "s/:x \"${CURRENT}px\"/:x \"${NEW}px\"/" "$YUCK"
elif [[ "$AXIS" == "y" ]]; then
    CURRENT=$(grep -oP '(?<=:y ")\d+(?=px")' "$YUCK")
    NEW=$(( CURRENT + DELTA ))
    sed -i "s/:y \"${CURRENT}px\"/:y \"${NEW}px\"/" "$YUCK"
fi

~/.cargo/bin/eww reload
