#!/bin/bash
# ── Screenshots ───────────────────────────────────────────────────────────────
# Role:     Freezes screen with swayimg + slurp region select + ImageMagick crop; outputs PNG to stdout
# Files:    screenshot-frozen.sh · screenshot-notify.sh · screenshot-clipboard-notify.sh
#           ~/.config/swappy/config                                    (editor settings)
#           ~/.config/systemd/user/screenshot-notify.service          (save daemon unit)
#           ~/.config/systemd/user/screenshot-clipboard-notify.service (clipboard daemon unit)
#           ~/.config/sway/modes/screenshot                           (mode + keybindings)
#           ~/.config/sway/config.d/01-definitions.conf               (grimshot, swappy, upload_pipe vars)
#           ~/.config/sway/autostart                                   ($swappy_notify, $screenshot_clipboard_notify)
#           ~/.config/sway/config.d/99-autostart-applications.conf    (exec_always daemon start)
# Programs: grim  slurp  swayimg  imagemagick  swappy  inotifywait  notify-send  wl-paste  wl-copy  curl
# Daemons:  screenshot-notify.service · screenshot-clipboard-notify.service  (sway-session.target)
# Triggers: Print keybind → screenshot mode → p / o / Shift+p / Shift+o
# Storage:  ~/Screenshots/  (or $XDG_SCREENSHOTS_DIR)
# ─────────────────────────────────────────────────────────────────────────────

set -e

TEMP_SCREENSHOT="/tmp/frozen-screenshot-$$.png"

cleanup() {
    pkill -f "swayimg.*$TEMP_SCREENSHOT" 2>/dev/null || true
    rm -f "$TEMP_SCREENSHOT"
}
trap cleanup EXIT

# 1. Capture full screen to freeze it
grim "$TEMP_SCREENSHOT"

# 2. Display frozen screenshot in fullscreen without info overlay
swayimg -F -e "swayimg.text.hide()" "$TEMP_SCREENSHOT" &
VIEWER_PID=$!

# Give swayimg time to render
sleep 0.2

# 3. Let user select area on the frozen image
GEOMETRY=$(slurp)

# 4. Kill the viewer
kill $VIEWER_PID 2>/dev/null || true
wait $VIEWER_PID 2>/dev/null || true

if [ -n "$GEOMETRY" ]; then
    # 5. Crop the selected area FROM the frozen screenshot using ImageMagick
    # Convert slurp geometry (X,Y WxH) to ImageMagick crop format (WxH+X+Y)
    IFS=' ' read -r position size <<< "$GEOMETRY"
    IFS=',' read -r x y <<< "$position"
    IFS='x' read -r w h <<< "$size"
    
    # Detect ImageMagick version and crop from the frozen screenshot
    if command -v magick &> /dev/null; then
        # ImageMagick 7
        magick "$TEMP_SCREENSHOT" -crop "${w}x${h}+${x}+${y}" +repage png:-
    else
        # ImageMagick 6
        convert "$TEMP_SCREENSHOT" -crop "${w}x${h}+${x}+${y}" +repage png:-
    fi
else
    exit 1
fi
