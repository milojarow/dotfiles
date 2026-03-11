#!/usr/bin/env bash
# wifi-connect.sh — connect to a wifi network.
# Args: <ssid> <known:true|false> <security>
# Spawned via swaymsg exec so eww does not kill it while rofi blocks.

SSID="$1"
KNOWN="$2"
SECURITY="$3"

if [ -z "$SSID" ]; then
    exit 1
fi

if [ "$KNOWN" = "true" ]; then
    # Known connection — bring it up by name (no password needed)
    nmcli connection up id "$SSID"
elif [ -n "$SECURITY" ]; then
    # Unknown secured network — ask for password
    password=$(rofi \
        -dmenu \
        -theme-str 'window {location: north; anchor: north; y-offset: 40px; width: 360px;}' \
        -theme-str 'listview {lines: 0;}' \
        -theme-str 'inputbar {padding: 10px 14px;}' \
        -p "Password for ${SSID}:")
    [ -z "$password" ] && exit 0
    nmcli device wifi connect "$SSID" password "$password"
else
    # Open network — connect directly
    nmcli device wifi connect "$SSID"
fi
