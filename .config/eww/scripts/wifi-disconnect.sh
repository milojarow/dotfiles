#!/usr/bin/env bash
# wifi-disconnect.sh — disconnect the active wifi device.

device=$(nmcli -t -f device,type,state dev \
    | awk -F: '$2=="wifi" && $3=="connected" {print $1; exit}')

[ -z "$device" ] && exit 0
nmcli device disconnect "$device"
