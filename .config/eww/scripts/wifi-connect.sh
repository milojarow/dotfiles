#!/usr/bin/env bash
# wifi-connect.sh — connect to a wifi network with visual feedback.
# Args: <ssid> <known:true|false> <security>
# Spawned via swaymsg exec so eww does not kill it while rofi blocks.

EWW=/home/milo/.cargo/bin/eww
SSID="$1"
KNOWN="$2"
SECURITY="$3"
BSSID="$4"
ERROR_PID_FILE=/tmp/eww-wifi-error-pid

[ -z "$SSID" ] && exit 1

# Kill any pending error-clear timer from a previous connection attempt
[ -f "$ERROR_PID_FILE" ] && kill "$(cat "$ERROR_PID_FILE")" 2>/dev/null
rm -f "$ERROR_PID_FILE"

# Instant visual feedback: button -> "connecting...", status bar -> visible
$EWW update wifi-error="" wifi-connecting="$SSID"

if [ "$KNOWN" = "true" ]; then
    # Known connection — bring it up by name (no password needed)
    output=$(nmcli connection up id "$SSID" 2>&1)
    rc=$?
elif [ -n "$SECURITY" ]; then
    # Unknown secured network — ask for password
    password=$(rofi \
        -dmenu \
        -theme-str 'window {location: north; anchor: north; y-offset: 40px; width: 360px;}' \
        -theme-str 'listview {lines: 0;}' \
        -theme-str 'inputbar {padding: 10px 14px;}' \
        -p "Password for ${SSID}:")
    if [ -z "$password" ]; then
        $EWW update wifi-connecting=""
        exit 0
    fi
    if [ -n "$BSSID" ]; then
        output=$(nmcli device wifi connect "$SSID" bssid "$BSSID" password "$password" 2>&1)
    else
        output=$(nmcli device wifi connect "$SSID" password "$password" 2>&1)
    fi
    rc=$?
else
    # Open network — connect directly
    if [ -n "$BSSID" ]; then
        output=$(nmcli device wifi connect "$SSID" bssid "$BSSID" 2>&1)
    else
        output=$(nmcli device wifi connect "$SSID" 2>&1)
    fi
    rc=$?
fi

# Connection attempt finished — clear connecting state
$EWW update wifi-connecting=""

if [ $rc -ne 0 ]; then
    # Extract meaningful error from nmcli output
    error_msg=$(echo "$output" | grep -i "error" | tail -1 | sed 's/^Error: //')
    [ -z "$error_msg" ] && error_msg="Connection failed"
    $EWW update wifi-error="${SSID}: ${error_msg}"
    # Auto-clear error after 8 seconds (background timer)
    (sleep 8 && $EWW update wifi-error="") &
    echo $! > "$ERROR_PID_FILE"
fi

# Wait for NetworkManager to settle the IN-USE flag before refreshing
if [ $rc -eq 0 ]; then
    elapsed=0
    until nmcli -t -f IN-USE device wifi list 2>/dev/null | grep -q '^\*'; do
        sleep 0.3
        (( elapsed++ ))
        (( elapsed >= 10 )) && break
    done
fi

# Refresh network list regardless of outcome
result=$(python3 ~/.config/eww/scripts/wifi-scan.py)
$EWW update wifi-networks="$result"
