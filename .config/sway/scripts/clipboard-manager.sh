#!/usr/bin/env bash
# ── Clipboard Functionality ──────────────────────────────────────────────────
# Role:     Interactive clipboard history browser — copy or delete entries
#           via rofi with Enter (copy) and Delete (remove) keybindings
# Files:    clipboard-manager.sh · clipboard-utf16-filter.py
#           ~/.config/rofi/themes/coffee-metal          (picker UI theme)
#           ~/.config/waybar/config.jsonc               (custom/clipboard module)
#           ~/.config/sway/autostart                    ($cliphist_store, $cliphist_watch, $clip-persist)
#           ~/.config/sway/config.d/01-definitions.conf ($clipboard, $clipboard-del)
#           ~/.config/sway/config.d/99-autostart-applications.conf
#           ~/.config/sway/modes/shutdown               ($purge_cliphist)
# Programs: cliphist  wl-paste  wl-copy  wl-clip-persist  waybar-signal  rofi
# Daemons:  wl-paste --watch clipboard-utf16-filter.py    (via $cliphist_store)
#           wl-paste --watch waybar-signal clipboard       (via $cliphist_watch)
#           wl-clip-persist --clipboard regular ...        (via $clip-persist)
# Callers:  $mod+Shift+p keybind (modes/default)
#           waybar left-click (config.jsonc)
# Storage:  ~/.cache/cliphist/db  (SQLite, purged on logout if configured)
# ─────────────────────────────────────────────────────────────────────────────

FONT="${1:-Roboto 11}"
ROFI_THEME="$HOME/.config/rofi/themes/coffee-metal"

while true; do
    # Exit if clipboard is empty
    if ! cliphist list | head -1 | grep -q .; then
        break
    fi

    # Process substitution feeds cliphist to rofi's stdin without a pipe,
    # so rofi runs in the current shell and $? captures its exit code directly.
    # -kb-custom-1 Delete   → exit code 10 on Delete key
    # -kb-remove-char-forward ""  → unbind Delete from default rofi action
    selection=$(rofi \
        -theme "$ROFI_THEME" \
        -dmenu \
        -font "$FONT" \
        -p "Clipboard (Enter=copy, Del=remove)" \
        -lines 10 \
        -kb-custom-1 Delete \
        -kb-remove-char-forward "" < <(cliphist list))
    exit_code=$?

    case $exit_code in
        0)  # Enter → copy selected item
            [ -n "$selection" ] && echo "$selection" | cliphist decode | wl-copy
            break
            ;;
        10) # Delete → remove selected item, loop
            [ -n "$selection" ] && echo "$selection" | cliphist delete
            waybar-signal clipboard
            ;;
        *)  # Escape or other → exit
            break
            ;;
    esac
done

waybar-signal clipboard
