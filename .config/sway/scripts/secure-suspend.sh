#!/bin/bash
# ~/.config/sway/scripts/secure-suspend.sh
# Suspend system - swayidle before-sleep handler will lock the screen

# Suspend the system (swayidle's before-sleep will trigger lock.sh)
systemctl suspend
