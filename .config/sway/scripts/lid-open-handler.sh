#!/bin/bash
# ~/.config/sway/scripts/lid-open-handler.sh
# Handle lid open: restore displays, keyboard backlight, and bluetooth

swaymsg "output * power on"

# Restore keyboard backlight to pre-close brightness
if [ -f /tmp/kbd-lid-brightness ]; then
    SAVED=$(cat /tmp/kbd-lid-brightness)
    brightnessctl --device="dell::kbd_backlight" set "${SAVED}" --quiet 2>/dev/null
    rm -f /tmp/kbd-lid-brightness
else
    brightnessctl --device="dell::kbd_backlight" set 2 --quiet 2>/dev/null
fi

~/.config/sway/scripts/bluetooth-reconnect.sh
