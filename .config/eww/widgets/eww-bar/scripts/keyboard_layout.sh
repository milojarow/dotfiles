#!/bin/bash

# get the current keyboard layout
layout=$(setxkbmap -query | awk '/layout/{print $2}')
variant=$(setxkbmap -query | awk '/variant/{print $2}')

if [[ $layout == "us" ]] && [[ $variant == "intl" ]]; then
    # format as JSON
    echo "{\"layout\": \"intl\"}" | jq
else
    # format as JSON
    echo "{\"layout\": \"$layout\"}" | jq
fi
