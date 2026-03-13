#!/usr/bin/env bash
if eww active-windows 2>/dev/null | grep -q "^bt-popup"; then
    eww close bt-popup
    eww update bt-popup-open=0
else
    eww open bt-popup
    eww update bt-popup-open=1
fi
