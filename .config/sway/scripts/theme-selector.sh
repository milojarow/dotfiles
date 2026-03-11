#!/usr/bin/env bash
# ── Palette Theming ───────────────────────────────────────────────────────────
# Role:     Main orchestrator for palette theme switching.
#           mode=menu: opens a wofi list, then on selection: symlinks the sway
#           theme.conf, copies foot-theme.ini, calls theme-apply-foot.sh to
#           push OSC colors to running terminals, reloads sway, regenerates
#           waybar CSS, and signals waybar.
#           mode=status: outputs a JSON icon for the waybar theme module.
# Files:    theme-selector.sh · theme-apply-foot.sh · theme-waybar.sh
#           theme-toggle.sh · theme-rofi.sh
#           ~/.config/sway/themes/<name>/theme.conf      (palette source)
#           ~/.config/sway/themes/<name>/foot-theme.ini  (terminal palette)
#           ~/.config/sway/definitions.d/theme.conf      (active sway theme, symlink)
#           ~/.config/foot/foot-theme.ini                (active foot theme, cp)
#           ~/.config/sway/templates/foot.ini            (shared foot template)
#           ~/.config/waybar/theme.css                   (auto-generated CSS)
#           ~/.config/rofi/Manjaro.rasi                  (auto-generated rofi colors)
# Programs: wofi  swaymsg  pkill
# Signals:  SIGUSR2     → waybar (CSS reload)
#           SIGRTMIN+17 → waybar (theme icon refresh)
# Man:      man palette-theming
# ─────────────────────────────────────────────────────────────────────────────
set -eu

# Paths
THEMES_DIR="$HOME/.config/sway/themes"
DEFINITIONS_DIR="$HOME/.config/sway/definitions.d"
CURRENT_THEME_LINK="$DEFINITIONS_DIR/theme.conf"
CURRENT_FOOT_THEME_LINK="$HOME/.config/foot/foot-theme.ini"

# Create directories if they don't exist
mkdir -p "$DEFINITIONS_DIR"
mkdir -p "$(dirname "$CURRENT_FOOT_THEME_LINK")"

# Get list of themes
get_themes() {
    find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort
}

# Apply selected theme
apply_theme() {
    local theme="$1"
    local theme_file="$THEMES_DIR/$theme/theme.conf"
    local foot_theme_file="$THEMES_DIR/$theme/foot-theme.ini"
    
    # Link Sway theme
    if [ -f "$theme_file" ]; then
        rm -f "$CURRENT_THEME_LINK"
        ln -sf "$theme_file" "$CURRENT_THEME_LINK"
    else
        echo "Error: Theme file not found at $theme_file"
        exit 1
    fi
    
    # Update foot theme and apply colors to all running terminals via OSC sequences
    if [ -f "$foot_theme_file" ]; then
        rm -f "$CURRENT_FOOT_THEME_LINK"
        cp "$foot_theme_file" "$CURRENT_FOOT_THEME_LINK"
        ~/.config/sway/scripts/theme-apply-foot.sh "$foot_theme_file" || true
    fi
    
    # Reload Sway to apply the new theme
    swaymsg reload
    # Regenerate per-app theme files
    ~/.config/sway/scripts/theme-waybar.sh
    ~/.config/sway/scripts/theme-rofi.sh
    pkill -SIGUSR2 waybar

    # Signal Waybar to update the theme icon
    pkill -RTMIN+17 waybar
}

# Initialize theme if not exists
initialize_theme() {
    if [ ! -e "$CURRENT_THEME_LINK" ]; then
        # Use dracula as the default if no theme is set
        if [ -d "$THEMES_DIR/dracula" ]; then
            apply_theme "dracula"
        else
            # Or use the first available theme
            local first_theme=$(get_themes | head -1)
            if [ -n "$first_theme" ]; then
                apply_theme "$first_theme"
            else
                echo "Error: No themes found"
                exit 1
            fi
        fi
    fi
}

# Get current theme
get_current_theme() {
    if [ -L "$CURRENT_THEME_LINK" ]; then
        theme_path=$(readlink -f "$CURRENT_THEME_LINK")
        echo "$theme_path" | grep -o "[^/]\+/theme.conf" | cut -d/ -f1
    else
        echo "No theme currently set"
    fi
}

# Determine if a theme is light or dark (based on common naming patterns)
is_light_theme() {
    local theme="$1"
    if [[ "$theme" =~ (light|latte|bright|white) ]]; then
        return 0  # true in bash
    else
        return 1  # false in bash
    fi
}

# Display menu and handle selection
display_menu() {
    initialize_theme
    current=$(get_current_theme)
    selected=$(get_themes | wofi --dmenu --prompt "Select theme (current: $current)" --insensitive)
    
    if [ -n "$selected" ]; then
        apply_theme "$selected"
    fi
}

# Status output for Waybar
status_output() {
    initialize_theme
    current=$(get_current_theme)

    # Default icon that will always be visible (color palette icon)
    icon="󰏘"  # Color palette icon

    # Generic icon selection based on theme name patterns
    if is_light_theme "$current"; then
        icon=""  # Sun/light theme icon
    else
        icon=""  # Moon/dark theme icon
    fi

    # Check for specific theme families to use more specific icons if possible
    if [[ "$current" =~ ^catppuccin- ]]; then
        icon=""  # Coffee cup icon for Catppuccin
    elif [[ "$current" =~ ^matcha- ]]; then
        icon="󰌪"  # Leaf icon for Matcha
    elif [[ "$current" == "dracula" ]]; then
        icon="󰭟"  # Bat icon for Dracula
    elif [[ "$current" =~ nordic ]]; then
        icon=""  # Snowflake icon for Nordic
    fi

    printf '{"alt":"%s","tooltip":"Current theme: %s\nClick to change theme","text":"%s"}\n' \
        "$current" "$current" "$icon"
}

# Main
case "${1:-}" in
    "menu")
        display_menu
        ;;
    "status")
        status_output
        ;;
    *)
        echo "Usage: $0 {menu|status}"
        exit 1
        ;;
esac
