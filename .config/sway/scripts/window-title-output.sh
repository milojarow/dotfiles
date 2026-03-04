#!/usr/bin/env sh
# ── Window Title ─────────────────────────────────────────────────────────────
# Role:     Thin reader invoked by waybar on each RTMIN+10 signal — checks
#           click-override expiry, then outputs the JSON cache written by
#           window-title.sh
# Files:    window-title.sh · window-title-output.sh · window-title-click.sh
#           window-title-rename.sh
#           ~/.config/waybar/config.jsonc               (custom/window-title, signal 10)
#           ~/.config/sway/config.d/99-autostart-applications.conf
# Programs: swaymsg  jq  pgrep  pstree  pkill
# Callers:  waybar exec (config.jsonc custom/window-title)
# Man:      man window-title
# ─────────────────────────────────────────────────────────────────────────────

OVERRIDE_FILE="/tmp/waybar-window-title-override-$USER"

# Check if click override is active and not expired
if [ -f "$OVERRIDE_FILE" ]; then
    override_text=$(sed -n '1p' "$OVERRIDE_FILE")
    expires=$(sed -n '2p' "$OVERRIDE_FILE")
    now=$(date +%s)
    if [ -n "$expires" ] && [ "$now" -lt "$expires" ]; then
        printf '{"text":"%s","tooltip":"App name (click to dismiss)","class":"window-title app-flash"}\n' "$override_text"
        exit 0
    else
        rm -f "$OVERRIDE_FILE"
    fi
fi

cat "/tmp/waybar-window-title-$USER.json" 2>/dev/null || \
    printf '{"text":"","tooltip":"No focused window","class":"empty"}\n'
