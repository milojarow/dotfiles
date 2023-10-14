#!/bin/bash

# File to keep track of the last update time
LAST_UPDATE_FILE="/var/lib/last_mirror_update"

# Get the current time in seconds since the epoch
current_time=$(date +%s)

# If the file exists, read the time of the last update
if [ -f "$LAST_UPDATE_FILE" ]; then
    last_update=$(cat "$LAST_UPDATE_FILE")
else
    last_update=0
fi

# Calculate the time difference
time_difference=$(( current_time - last_update ))

# 1209600 seconds is equivalent to two weeks
if [ $time_difference -ge 1209600 ]; then
    # Fetch the latest mirrorlist
    curl -o /tmp/mirrorlist "https://archlinux.org/mirrorlist/all/"

    # Uncomment all mirrors
    sed -i 's/^#Server/Server/' /tmp/mirrorlist

    # Move the new mirrorlist into place
    mv /tmp/mirrorlist /etc/pacman.d/mirrorlist

    # Update the last update time
    echo $current_time > "$LAST_UPDATE_FILE"
fi
