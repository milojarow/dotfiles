#!/bin/sh

case $1 in
  'status')
    # Obtiene la lista de actualizaciones disponibles (redirigiendo errores por si no existe)
    updates=$(checkupdates 2>/dev/null)
    count=$(printf '%s' "$updates" | wc -l)
    # Imprime un JSON con el número de actualizaciones y la lista en el tooltip
    printf '{"text":"%s","tooltip":"%s"}' "$count" "$(printf '%s' "$updates" | sed 's/\n$//')"
    ;;
  'check')
    # Retorna true si hay al menos una actualización
    [ $(checkupdates 2>/dev/null | wc -l) -gt 0 ]
    exit $?
    ;;
  'upgrade')
    # Intenta usar pacseek o topgrade si están disponibles, sino recurre a pacman
    if [ -x "$(command -v pacseek)" ]; then
      xdg-terminal-exec pacseek -u
    elif [ -x "$(command -v topgrade)" ]; then
      xdg-terminal-exec topgrade
    else
      xdg-terminal-exec pacman -Syu
    fi
    ;;
esac

