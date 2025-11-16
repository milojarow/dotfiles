#!/bin/bash

# Prevent multiple lock instances - if swaylock is already running, exit
if pgrep -x swaylock > /dev/null; then
    exit 0
fi

# Use consistent filename to overwrite previous image
SCREENSHOT="/tmp/swaylock-blur.png"

# Capture the screen
grim "$SCREENSHOT"

# Detecta qué comando usar para ImageMagick
if command -v magick &> /dev/null; then
    # Para ImageMagick 7 - aumentado el nivel de desenfoque de 8 a 15
    magick "$SCREENSHOT" -blur 0x15 "$SCREENSHOT"
else
    # Para ImageMagick 6 o anterior - aumentado el nivel de desenfoque de 8 a 15
    convert "$SCREENSHOT" -blur 0x15 "$SCREENSHOT"
fi

# Bloquea la pantalla con la imagen desenfocada
swaylock -i "$SCREENSHOT"

# Elimina la captura cuando termine swaylock
rm "$SCREENSHOT"
