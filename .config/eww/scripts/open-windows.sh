#!/bin/bash
# Defines which eww windows to open on startup.
# Each window is closed before opening to guarantee exactly one instance.

open_window() {
    eww close "$1" 2>/dev/null
    eww open "$1"
}

open_window eww-bar
open_window arch-logo-window
open_window disk-widget
open_window activate-linux
open_window sysmonitor-window
open_window temps-window
open_window usb-widget
open_window clock
