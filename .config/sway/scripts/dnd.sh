#!/bin/sh

case $1'' in
'status') 
    current_mode=$(makoctl mode | tail -1)
    is_dnd=$(echo "$current_mode" | grep -q 'do-not-disturb' && echo dnd || echo default)
    printf '{\"alt\":\"%s\",\"tooltip\":\"mode: %s\"}' "$is_dnd" "$current_mode"
    ;;
'restore')
    makoctl restore
    ;;
'toggle')
    makoctl mode | grep 'do-not-disturb' && makoctl mode -r do-not-disturb || makoctl mode -a do-not-disturb
    ;;
esac
