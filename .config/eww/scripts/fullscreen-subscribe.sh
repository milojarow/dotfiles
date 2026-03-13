#!/usr/bin/env bash
# fullscreen-subscribe.sh — eww deflisten source.
# Emits "true"/"false" based on fullscreen state and directly manages
# arch-logo-window visibility (close on fullscreen, reopen on exit).

EWW=/home/milo/.cargo/bin/eww

# Kill any prior instance of this script (prevents duplicate listeners on eww restart)
for pid in $(pgrep -f "fullscreen-subscribe.sh"); do
    [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null
done

is_fullscreen() {
    # Only check con/floating_con nodes — workspace nodes always have
    # fullscreen_mode=1 in sway's tree, which would cause false positives.
    swaymsg -t get_tree \
        | jq 'any(.. | objects | select(.type? == "con" or .type? == "floating_con") | .fullscreen_mode? // 0; . >= 1)' 2>/dev/null
}

last_state=""

handle_state() {
    local state
    state=$(is_fullscreen)

    # Only act when state actually changes to avoid redundant eww calls
    if [ "$state" = "$last_state" ]; then
        return
    fi
    last_state="$state"

    if [ "$state" = "true" ]; then
        $EWW close arch-logo-window 2>/dev/null
    else
        $EWW open arch-logo-window 2>/dev/null
    fi

    echo "$state"
}

# Emit initial state
handle_state

# Subscribe to window + workspace events (compact JSON lines via jq).
# Re-check the full tree on every event — authoritative and simple.
# Loop reconnects if swaymsg drops (e.g. sway reload).
while true; do
    swaymsg -t subscribe -m '["window", "workspace"]' \
        | jq --unbuffered -c '.' 2>/dev/null \
        | while IFS= read -r _event; do
            handle_state
          done
    # Subscription dropped — recheck state before reconnecting
    handle_state
    sleep 1
done
