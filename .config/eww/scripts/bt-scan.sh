#!/usr/bin/env bash
# Toggle bluetooth scan. If already scanning: stop. Otherwise: start, auto-stop after 15s.
if bluetoothctl show 2>/dev/null | grep -q "Discovering: yes"; then
    bluetoothctl scan off
else
    (bluetoothctl scan on; sleep 15; bluetoothctl scan off) &
fi
