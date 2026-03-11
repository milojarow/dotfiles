#!/usr/bin/env bash
# save-eww-var.sh <yuck-file> <var-name>
# Writes the current live value of a defvar back to its default in the yuck file.
# Safe to run on files with Nerd Font glyphs — only touches the defvar line.

FILE="$1"
VAR="$2"

current=$(/home/milo/.cargo/bin/eww state | grep "^${VAR}:" | awk '{print $NF}')
sed -i "s|(defvar ${VAR} -\?[0-9]\+)|(defvar ${VAR} ${current})|" "$FILE"
