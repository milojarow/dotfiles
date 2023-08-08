#!/bin/bash

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

