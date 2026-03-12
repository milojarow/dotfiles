#!/usr/bin/env bash
# ── Palette Theming ───────────────────────────────────────────────────────────
# Role:     Generates ~/.config/eww/styles/theme.scss from the active sway theme.
#           Reads ~/.config/sway/definitions.d/theme.conf, resolves
#           $background-color, $text-color, $accent-color, and $selection-color
#           (supports one level of variable indirection), and emits SCSS variables.
#           Called by theme-selector.sh on every theme switch.
#           eww auto-reloads SCSS on file change, so no eww reload is needed.
# Files:    theme-eww.sh
#           ~/.config/sway/definitions.d/theme.conf  (active theme symlink, input)
#           ~/.config/eww/styles/theme.scss           (auto-generated SCSS, output)
# Programs: grep
# Storage:  ~/.config/eww/styles/theme.scss — overwritten on every theme switch
# ─────────────────────────────────────────────────────────────────────────────
set -u

DEFINITIONS_DIR="$HOME/.config/sway/definitions.d"
CURRENT_THEME_LINK="$DEFINITIONS_DIR/theme.conf"
EWW_THEME_SCSS="$HOME/.config/eww/styles/theme.scss"

generate_theme_scss() {
    if [ ! -L "$CURRENT_THEME_LINK" ]; then
        echo "No theme currently set" >&2
        return 1
    fi

    theme_path=$(readlink -f "$CURRENT_THEME_LINK")
    theme_name=$(basename "$(dirname "$theme_path")")

    # Resolve a sway variable to its hex color value (handles one level of indirection)
    # e.g. "background-color" → finds "set $background-color $color0" → finds "set $color0 #1a1b26" → "#1a1b26"
    resolve_var() {
        local path="$1" varname="$2"
        local value
        value=$(grep -oP "set \\\$$varname\s+\K\S+" "$path" | head -1)
        if [[ "$value" == "#"* ]]; then
            echo "$value"
        elif [[ "$value" == '$'* ]]; then
            resolve_var "$path" "${value#$}"
        fi
    }

    bg=$(resolve_var "$theme_path" "background-color")
    fg=$(resolve_var "$theme_path" "text-color")
    accent=$(resolve_var "$theme_path" "accent-color")
    selection=$(resolve_var "$theme_path" "selection-color")
    color2=$(resolve_var "$theme_path" "color2")
    color11=$(resolve_var "$theme_path" "color11")

    bg="${bg:-#1c1c1c}"
    fg="${fg:-#ffffff}"
    accent="${accent:-#1a5fb4}"
    selection="${selection:-#282828}"
    color2="${color2:-#3B758C}"
    color11="${color11:-#98971a}"

    # Stop eww daemon before writing theme.scss.
    # The daemon watches config files via inotify; writing while it runs triggers a
    # concurrent hot-reload from the daemon AND from each persistent window manager
    # process (eww open keeps a manager alive per window), causing duplicate windows.
    # Stopping first guarantees exactly one startup with the new theme.
    /usr/bin/systemctl --user stop eww.service

    cat > "$EWW_THEME_SCSS" << EOF
// Auto-generated — do not edit manually.
// Source: ~/.config/sway/definitions.d/theme.conf
// Theme: $theme_name

\$theme-bg:        $bg;
\$theme-fg:        $fg;
\$theme-accent:    $accent;
\$theme-selection: $selection;
\$color2:          $color2;
\$color11:         $color11;
EOF

    # Start eww daemon fresh — reads the new theme.scss, ExecStartPost opens all windows.
    /usr/bin/systemctl --user start eww.service

    echo "Generated eww theme SCSS for theme: $theme_name"
}

generate_theme_scss
