#!/bin/bash
# Wait for system to stabilize after lid open
sleep 3

# Get Bluetooth device MAC address (DEA700)
BT_MAC="44:1D:B1:4B:0B:A0"

# Check if device is connected
if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
    # Force reconnect to fix zombie state
    bluetoothctl disconnect "$BT_MAC"
    sleep 2
    bluetoothctl connect "$BT_MAC"
fi
