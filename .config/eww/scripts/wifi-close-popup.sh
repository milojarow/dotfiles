#!/usr/bin/env bash
EWW=/home/milo/.cargo/bin/eww
$EWW close eww-wifi-popup 2>/dev/null
$EWW update wifi-popup-open=0
