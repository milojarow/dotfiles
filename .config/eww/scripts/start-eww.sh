#!/bin/bash
# Entry point called by sway exec_always.
# Waits for eww daemon to be ready, then delegates window opening.

until eww ping &>/dev/null; do
    sleep 0.2
done

~/.config/eww/scripts/open-windows.sh
