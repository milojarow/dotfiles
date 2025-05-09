#!/bin/sh
# Clipboard watcher that signals Waybar when clipboard changes

# Asegura que solo se ejecuta una instancia
pgrep -f "wl-paste --watch bash -c 'pkill -RTMIN+9 waybar'" && exit

# Observa cambios en el clipboard y envía señal a waybar
wl-paste --watch bash -c 'pkill -RTMIN+9 waybar'
