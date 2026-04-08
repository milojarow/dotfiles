#!/usr/bin/env bash
EWW=/home/milo/.cargo/bin/eww
timeout 3s $EWW update wifi-popup-open=0
timeout 3s $EWW close eww-wifi-popup
