#!/usr/bin/env bash
# Interactive clipboard manager with inline delete support

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
