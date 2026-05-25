#!/usr/bin/env bash
# feature: wifi
# role:    action
# wifi-pw-submit.sh — close the eww password prompt and connect with the typed key.
# Invoked by the prompt's input :onaccept as:  wifi-pw-submit.sh '{}'
# The password arrives as $1 (single-quoted in the yuck, so spaces / $ / ` are
# preserved literally). setsid -f detaches the connect so eww's onaccept timeout
# can't kill it mid-connection, and passes the password as a literal argv slot
# (no shell re-parsing — avoids the swaymsg-exec quoting trap).

EWW=/home/milo/.cargo/bin/eww
pw="$1"

"$EWW" close wifi-password-prompt 2>/dev/null

[ -z "$pw" ] && exit 0   # empty submit = cancel

ssid=$("$EWW" get wifi-pw-ssid)
bssid=$("$EWW" get wifi-pw-bssid)
sec=$("$EWW" get wifi-pw-security)

setsid -f ~/.config/eww/scripts/wifi-connect.sh "$ssid" false "$sec" "$bssid" "$pw" >/dev/null 2>&1
