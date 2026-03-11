#!/usr/bin/env bash
# volume-scroll.sh — called by eww eventbox :onscroll with "up" or "down"
case "$1" in
    up)   pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
esac
