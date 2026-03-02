#!/bin/bash
# Wait for eww daemon to be ready, then open widgets.
# Called by sway exec_always on startup and reload.

until eww ping &>/dev/null; do
    sleep 0.2
done
eww open activate-linux
