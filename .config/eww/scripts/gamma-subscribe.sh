#!/usr/bin/env bash
# gamma-subscribe.sh — eww deflisten for gamma correction (wlsunset) state.
#
# Named pipe receives toggle signals from the button onclick.
# Delegates all wlsunset start/stop logic to sunset.sh (handles geolocation).

ICON_ON=$'\xf3\xb0\x8c\xb5'   # 󰌵  gamma on  (U+F0335)
ICON_OFF=$'\xf3\xb0\x8c\xb6'  # 󰌶  gamma off (U+F0336)
PIPE="/tmp/eww-gamma"

emit() {
    if pkill -x -0 wlsunset 2>/dev/null; then
        printf '{"active": true, "icon": "%s"}\n' "$ICON_ON"
    else
        printf '{"active": false, "icon": "%s"}\n' "$ICON_OFF"
    fi
}

toggle() {
    ~/.config/sway/scripts/sunset.sh toggle
    emit
}

force_warm() {
    ~/.config/sway/scripts/sunset.sh force-warm
    emit
}

rm -f "$PIPE"
mkfifo "$PIPE"

emit

while read -r cmd < "$PIPE"; do
    case "$cmd" in
        w) force_warm ;;
        *) toggle ;;
    esac
done
