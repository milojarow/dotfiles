#!/usr/bin/env bash
# vps-storage.sh -- eww deflisten for VPS disk usage via SSH
# Usage: vps-storage.sh <hostname>
# Emits JSON: {"used":"4.5G","total":"25.0G","pct":18}
# Re-fetches on network events and every 10 minutes.

HOST="${1:?Usage: vps-storage.sh <hostname>}"
REFRESH=600

fetch() {
    local data
    data=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "$HOST" "df -B1 / | tail -1" 2>/dev/null)
    if [[ -n "$data" ]]; then
        echo "$data" | awk '{
            pct = int($3 / $2 * 100)
            used_gb = sprintf("%.1f", $3 / 1073741824)
            total_gb = sprintf("%.1f", $2 / 1073741824)
            printf "{\"used\":\"%sG\",\"total\":\"%sG\",\"pct\":%d}\n", used_gb, total_gb, pct
        }'
    else
        echo '{"used":"?","total":"?","pct":0}'
    fi
}

# Initial fetch
fetch

# Main loop: react to network events, periodic refresh as fallback
nmcli monitor 2>/dev/null | while true; do
    if read -t "$REFRESH" -r _line; then
        # Network event — brief delay for DNS/routing stabilization
        sleep 2
        fetch
    else
        # Timeout — periodic refresh
        fetch
    fi
done
