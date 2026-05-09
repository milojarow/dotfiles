#!/usr/bin/env bash
# feature: wifi
# role:    action
EWW=/home/milo/.cargo/bin/eww

if [[ "$($EWW get wifi-popup-open 2>/dev/null)" == "1" ]]; then
    $EWW close wifi-popup 2>/dev/null
    $EWW update wifi-popup-open=0
else
    $EWW open wifi-popup 2>/dev/null
    $EWW update wifi-popup-open=1
    ~/.config/eww/scripts/wifi-public-ip.sh &
fi
