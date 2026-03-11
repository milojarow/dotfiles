#!/bin/bash
#
# disk-usage.sh - Compute disk usage percentages for home directories
# Outputs JSON with each category's share of total disk (percentage)

HOME_DIR="$HOME"

# Total partition size in 1K-blocks
DISK_TOTAL=$(df --output=size "$HOME_DIR" | tail -1)
[ -z "$DISK_TOTAL" ] || [ "$DISK_TOTAL" -le 0 ] && DISK_TOTAL=1

# Single-pass traversal: summarize immediate children of home
du_home=$(du -d1 -k "$HOME_DIR" 2>/dev/null)

# Extract the 1K-block size for a given exact path
size_of() {
    echo "$du_home" | awk -v p="$1" '$2 == p { print $1; exit }'
}

docs=$(size_of "$HOME_DIR/Documents"); docs=${docs:-0}
pics=$(size_of "$HOME_DIR/Pictures");  pics=${pics:-0}
dls=$(size_of  "$HOME_DIR/Downloads"); dls=${dls:-0}
vids=$(size_of "$HOME_DIR/Videos");    vids=${vids:-0}
home_total=$(size_of "$HOME_DIR");     home_total=${home_total:-0}

# Other = everything in home that is not the four named directories
other=$(( home_total - docs - pics - dls - vids ))
[ "$other" -lt 0 ] && other=0

# /root directory (falls back to 0 if not readable)
root_size=$(du -sk /root 2>/dev/null | awk '{print $1}')
root_size=${root_size:-0}

# Return percentage of total disk size
pct() {
    awk -v s="$1" -v t="$DISK_TOTAL" 'BEGIN { printf "%.1f", (s / t) * 100 }'
}

printf '{"documents":%s,"pictures":%s,"downloads":%s,"videos":%s,"other":%s,"root":%s}\n' \
    "$(pct "$docs")" "$(pct "$pics")" "$(pct "$dls")" "$(pct "$vids")" \
    "$(pct "$other")" "$(pct "$root_size")"
