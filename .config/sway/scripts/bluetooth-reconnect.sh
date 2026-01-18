#!/bin/bash
# Bluetooth reconnect failsafe for lid resume
# Should become unnecessary after btusb autosuspend fix

LOG_FILE="$HOME/.local/log/bluetooth-reconnect.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Wait for system to stabilize
sleep 3

BT_MAC="44:1D:B1:4B:0B:A0"

# Check if device is in zombie state
if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
    # Check if audio is actually working
    if ! pactl list sinks short | grep -q "bluez_output.44_1D_B1_4B_0B_A0.*RUNNING\|IDLE"; then
        echo "[$(date)] Zombie connection detected, forcing reconnect" >> "$LOG_FILE"
        bluetoothctl disconnect "$BT_MAC"
        sleep 2
        bluetoothctl connect "$BT_MAC"
    fi
fi
