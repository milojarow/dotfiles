#!/bin/bash

# Help message function
show_help() {
  echo "Usage: update_mirrorlist.sh [-h|--help]"
  echo ""
  echo "Automatically updates the Arch Linux mirrorlist."
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit."
  echo ""
  echo "Files needed for this script to work:"
  echo "  /var/lib/last_mirror_update    Stores the time of the last mirror update."
  echo "  /etc/systemd/system/update-mirrorlist.service    Systemd service file."
  echo "  /etc/networkd-dispatcher/routable.d/50-update-mirrorlist    Network dispatcher file."
}

# Check for help flag
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  show_help
  exit 0
fi

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
