#!/bin/bash

# Function to display help message
display_help() {
  echo "Usage: save_networks.sh"
  echo "Save the names and passwords of connected Wi-Fi networks to a file."
  echo
  echo "This script retrieves the UUIDs of all network connections, extracts the names and passwords of Wi-Fi networks,"
  echo "and saves them to ~/.saved_networks. Existing entries are not duplicated."
  echo
  echo "Example:"
  echo "  ./save_networks.sh    # Saves connected Wi-Fi network names and passwords"
  echo
  echo "Note: This script does not accept any options or arguments and should be run without any."
}

# Check for the --help option
if [ "$1" == "--help" ]; then
  display_help
  exit 0
fi

# Check if any unwanted arguments are provided
if [ "$#" -ne 0 ]; then
    echo "No arguments expected. Use 'save_networks.sh --help' for more information."
    exit 1
fi

FILE="/home/milo/.saved_networks"

touch $FILE
chmod 600 $FILE

for uuid in $(nmcli -g UUID connection show); do
    name=$(nmcli -g connection.id connection show $uuid)
    password=$(nmcli -s -g 802-11-wireless-security.psk connection show $uuid)
    
    if [ ! -z "$password" ]; then
        entry="$name: $password"
        grep -qxF "$entry" $FILE || echo "$entry" >> $FILE
    fi
done
