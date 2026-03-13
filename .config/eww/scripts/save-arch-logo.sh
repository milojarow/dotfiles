#!/usr/bin/env bash
# save-arch-logo.sh <arch-logo.yuck>
# Collapses spacer offsets into the defwindow geometry, then zeroes the spacers.
# Result: small window (~50x50px) positioned exactly where the icon appears on screen.
# The base window origin is -58,-58 (off-screen anchor), so:
#   icon screen x = -58 + arch-icon-x
#   icon screen y = -58 + arch-icon-y

FILE="$1"
EWW=/home/milo/.cargo/bin/eww

# Read live spacer values
ix=$($EWW state | grep "^arch-icon-x:" | awk '{print $NF}')
iy=$($EWW state | grep "^arch-icon-y:" | awk '{print $NF}')

# Compute new window position absorbing the spacer offset
new_x=$(( -58 + ix ))
new_y=$(( -58 + iy ))

# Rewrite defwindow geometry in the yuck file
sed -i \
  -e "s|:x \"-\?[0-9]\+px\"|:x \"${new_x}px\"|" \
  -e "s|:y \"-\?[0-9]\+px\"|:y \"${new_y}px\"|" \
  -e "s|:width \"[0-9]\+px\"|:width \"50px\"|" \
  -e "s|:height \"[0-9]\+px\"|:height \"50px\"|" \
  "$FILE"

# Zero out spacer defvar defaults (no spacers needed when window is repositioned)
sed -i \
  -e "s|(defvar arch-icon-x -\?[0-9]\+)|(defvar arch-icon-x 0)|" \
  -e "s|(defvar arch-icon-y -\?[0-9]\+)|(defvar arch-icon-y 0)|" \
  "$FILE"

# Live-update spacers to 0, then reopen to apply the new window geometry
$EWW update arch-icon-x=0 arch-icon-y=0
$EWW close arch-logo-window
$EWW open  arch-logo-window
