#!/usr/bin/env sh
# Thin reader for waybar custom/window-title module
# The actual processing is done by window-title.sh which caches results here
cat "/tmp/waybar-window-title-$USER.json" 2>/dev/null || \
    printf '{"text":"","tooltip":"No focused window","class":"empty"}\n'
