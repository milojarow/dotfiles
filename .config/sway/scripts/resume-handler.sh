#!/bin/bash
# ── Lock Screen & Idle ────────────────────────────────────────────────────────
# Role:     Restore keyboard backlight after system wake from suspend
# Files:    secure-suspend.sh · auto-idle-timeout.sh · idle-timeout.sh
# State:    /tmp/kbd-suspend-brightness  (saved by secure-suspend.sh before sleep)
# Trigger:  swayidle after-resume event (configured in auto-idle-timeout.sh / idle-timeout.sh)
# Note:     swaymsg "output * power on" is called before this script via after-resume
# ─────────────────────────────────────────────────────────────────────────────

# Reopen eww windows lost during suspend
/home/milo/.config/eww/scripts/open-windows.sh

# Restore keyboard backlight to pre-suspend level, or default to 2
if [[ -f /tmp/kbd-suspend-brightness ]]; then
    SAVED=$(cat /tmp/kbd-suspend-brightness)
    brightnessctl --device="dell::kbd_backlight" set "${SAVED}" --quiet 2>/dev/null
    rm -f /tmp/kbd-suspend-brightness
else
    brightnessctl --device="dell::kbd_backlight" set 2 --quiet 2>/dev/null
fi
