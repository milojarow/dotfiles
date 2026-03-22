#!/bin/bash
# Fetch disk usage from selene VPS via SSH
# Output: {"used":"4.5G","total":"25.0G","pct":18}

data=$(ssh -o ConnectTimeout=5 -o BatchMode=yes selene "df -B1 / | tail -1" 2>/dev/null)

if [[ -z "$data" ]]; then
  # No connection — wait for network up event, then retry once
  nmcli monitor 2>/dev/null | grep -m1 -q "connected"
  data=$(ssh -o ConnectTimeout=5 -o BatchMode=yes selene "df -B1 / | tail -1" 2>/dev/null)
fi

if [[ -z "$data" ]]; then
  echo '{"used":"?","total":"?","pct":0}'
  exit 0
fi

echo "$data" | awk '{
  pct = int($3 / $2 * 100)
  used_gb = sprintf("%.1f", $3 / 1073741824)
  total_gb = sprintf("%.1f", $2 / 1073741824)
  printf "{\"used\":\"%sG\",\"total\":\"%sG\",\"pct\":%d}\n", used_gb, total_gb, pct
}'
