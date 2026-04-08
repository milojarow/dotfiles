#!/usr/bin/env bash
EWW=/home/milo/.cargo/bin/eww

if timeout 3s $EWW active-windows 2>/dev/null | grep -q "eww-wifi-popup"; then
    timeout 3s $EWW close eww-wifi-popup
    timeout 3s $EWW update wifi-popup-open=0
else
    timeout 3s $EWW open eww-wifi-popup
    timeout 3s $EWW update wifi-popup-open=1
fi
