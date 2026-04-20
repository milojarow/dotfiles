#!/usr/bin/env bash
EWW=/home/milo/.cargo/bin/eww

if [[ "$($EWW get gamma-popup-revealed 2>/dev/null)" == "true" ]]; then
    $EWW update gamma-popup-revealed=false
else
    $EWW update gamma-popup-revealed=true
fi
