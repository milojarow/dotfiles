#!/bin/bash
# Re-patches .desktop files to prepend prime-run to Exec= lines.
# Reads app list from ~/.config/prime-run-apps.conf
# Each line format: package:desktop-filename:exec-pattern

CONF="$HOME/.config/prime-run-apps.conf"
LOCAL_DIR="$HOME/.local/share/applications"
SYSTEM_DIR="/usr/share/applications"

[[ -f "$CONF" ]] || exit 0

while IFS=: read -r _pkg desktop pattern; do
    [[ -z "$desktop" || "$desktop" == \#* ]] && continue
    src="$SYSTEM_DIR/$desktop"
    dst="$LOCAL_DIR/$desktop"
    [[ -f "$src" ]] || continue
    cp "$src" "$dst"
    sed -i "s|^Exec=$pattern|Exec=prime-run $pattern|" "$dst"
done < "$CONF"
