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
    # Wait for eww daemon to be responsive before opening windows
    timeout=20
    elapsed=0
    until eww ping 2>/dev/null; do
      sleep 0.5
      elapsed=$((elapsed + 1))
      [ "$elapsed" -ge "$((timeout * 2))" ] && break
    done
    /home/milo/.config/eww/scripts/open-windows.sh
  fi
done
