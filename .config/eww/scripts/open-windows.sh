#!/bin/bash
# Defines which eww windows to open on startup.
# flock prevents concurrent runs (e.g. two eww-resume-watch.sh firing at once)
# which would create duplicate layer-shell surfaces.
exec 9>/tmp/eww-open-windows.lock
flock 9

open_window() {
    eww close "$1" 2>/dev/null
    eww open "$1"
}

open_window eww-bar
open_window disk-widget
open_window activate-linux
open_window sysmonitor-window
open_window temps-window
open_window usb-widget
open_window bt-widget
open_window timer-widget
open_window clock
open_window selene-storage-window
open_window mongo-tunnel-window
