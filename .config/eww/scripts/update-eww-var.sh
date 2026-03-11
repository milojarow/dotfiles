#!/usr/bin/env bash
# update-eww-var.sh <var-name> <delta>
# Increments a defvar by delta without touching any file or requiring a reload.

VAR="$1"
DELTA="$2"

current=$(/home/milo/.cargo/bin/eww state | grep "^${VAR}:" | awk '{print $NF}')
/home/milo/.cargo/bin/eww update "${VAR}=$((current + DELTA))"
