#!/usr/bin/env bash
# Reads the active window-title flash override for the eww bar defpoll.
# Outputs the flash text if the file exists and has not expired.
# Outputs nothing when no override is active or it has expired.

FLASH_FILE="/tmp/eww-window-title-flash-${USER}"

[ -f "$FLASH_FILE" ] || exit 0

text=$(sed -n '1p' "$FLASH_FILE")
expires=$(sed -n '2p' "$FLASH_FILE")
now=$(date +%s)

if [ -n "$expires" ] && [ "$now" -lt "$expires" ]; then
    printf '%s' "$text"
else
    rm -f "$FLASH_FILE"
fi
