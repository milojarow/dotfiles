#!/usr/bin/env bash
EWW=/home/milo/.cargo/bin/eww

if [[ "$($EWW get wifi-popup-open 2>/dev/null)" == "1" ]]; then
    $EWW close eww-wifi-popup 2>/dev/null
    $EWW update wifi-popup-open=0
else
    $EWW open eww-wifi-popup 2>/dev/null
    $EWW update wifi-popup-open=1
fi
