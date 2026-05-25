#!/usr/bin/env bash
# feature: wifi
# role:    action
EWW=/home/milo/.cargo/bin/eww
$EWW close wifi-popup 2>/dev/null
$EWW update wifi-popup-open=0
$EWW update wifi-password=""
