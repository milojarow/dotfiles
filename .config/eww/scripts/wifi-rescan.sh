#!/usr/bin/env bash
# wifi-rescan.sh — force a hardware wifi rescan and immediately update eww.
# Spawned via swaymsg exec from the rescan button.

EWW=/home/milo/.cargo/bin/eww

nmcli device wifi rescan 2>/dev/null || true
result=$(python3 /home/milo/.config/eww/scripts/wifi-scan.py)
$EWW update wifi-networks="$result"
