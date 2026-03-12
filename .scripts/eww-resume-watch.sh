#!/bin/bash
# Listens for system resume via D-Bus PrepareForSleep signal.
# When the system wakes from suspend/hibernate, reopens eww windows.

export PATH="/home/milo/.cargo/bin:/usr/local/bin:/usr/bin:/bin"

dbus-monitor --system \
  "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" \
  2>/dev/null |
while read -r line; do
  # PrepareForSleep(false) = system just resumed
  if echo "$line" | grep -q 'boolean false'; then
    # Wait for eww daemon to be responsive
    timeout=20
    elapsed=0
    until eww ping 2>/dev/null; do
      sleep 0.5
      elapsed=$((elapsed + 1))
      [ "$elapsed" -ge "$((timeout * 2))" ] && break
    done
    # Wait for sway to re-register monitors (race condition on resume)
    elapsed=0
    until swaymsg -t get_outputs 2>/dev/null | grep -q '"active": true'; do
      sleep 0.5
      elapsed=$((elapsed + 1))
      [ "$elapsed" -ge "$((timeout * 2))" ] && break
    done
    /home/milo/.config/eww/scripts/open-windows.sh
  fi
done
