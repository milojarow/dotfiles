#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Verificar que el directorio existe y tiene imágenes
if [[ ! -d "$WALLPAPER_DIR" ]] || [[ -z "$(ls -A "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null)" ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Seleccionar wallpaper aleatorio
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

# Aplicar wallpaper
swaymsg "output * bg \"$WALLPAPER\" fill"

echo "Applied wallpaper: $WALLPAPER"
