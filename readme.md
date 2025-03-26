# Sway Desktop Environment Configuration

## Touchpad Configuration

The touchpad is configured with the following specific settings (as seen with `swaymsg -t get_inputs | jq`):

```json
{
  "identifier": "1739:52759:SYNA32B6:00_06CB:CE17_Touchpad",
  "name": "SYNA32B6:00 06CB:CE17 Touchpad",
  "type": "touchpad",
  "scroll_factor": 1.0,
  "libinput": {
    "send_events": "enabled",
    "tap": "enabled",
    "tap_button_map": "lrm",
    "tap_drag": "enabled",
    "tap_drag_lock": "disabled",
    "accel_speed": 0.0,
    "accel_profile": "adaptive",
    "natural_scroll": "enabled",
    "left_handed": "disabled",
    "click_method": "button_areas",
    "clickfinger_button_map": "lrm",
    "middle_emulation": "disabled",
    "scroll_method": "two_finger",
    "dwt": "enabled",
    "dwtp": "enabled"
  },
  "vendor": 1739,
  "product": 52759
}
```

This configuration enables:
- Tap-to-click functionality
- Natural scrolling
- Two-finger scrolling
- Adaptive acceleration
- Specific click and drag behaviors

## Dependencies

### Window Manager and Desktop Environment
- `sway`
- `waybar`

### Terminal and Recording
- `foot`
- `wf-recorder`

### System Utilities
- `brightnessctl` (screen brightness)
- `wlsunset` (color temperature)
- `cliphist` / `wl-clip-persist` (clipboard management)

### Overlays and Notifications
- `nwg-wrapper`
- `slurp`
- `libnotify` (notify-send)
- `mako` (notification daemon)

### Update Management
- `pacseek` or `topgrade` or `pamac-manager`

### Python and Scripting
- `python3`
- Python modules:
  - `i3ipc`
  - `requests`
  - `configparser`
  - `dbus-python`

### CLI and Utility Tools
- `jq`
- `bc`
- `curl`
- `inotify-tools`
- `wob`

### Lock and Monitor Management
- `gtklock` or `waylock` or `swaylock`
- `kanshi`
- `idlehack`

### File Management and Applications
- `pcmanfm-qt` (or `pcmanfm`)
- `noisetorch` (optional)

### Wayland Applications
- `rofi`
- `rofimoji`

### Additional Tools
- `gh` (GitHub CLI, optional)
- `zeit` (task tracking)
- `wtype`
- `xdg-utils`
- `pcregrep`

### Installation Commands

#### Pacman (Official Repositories)
```bash
sudo pacman -S sway waybar foot wf-recorder brightnessctl wlsunset libnotify mako python3 python-i3ipc python-requests python-configparser python-dbus jq bc curl inotify-tools wob gtklock kanshi slurp rofi xdg-utils pcregrep
```

#### Yay (AUR Packages)
```bash
yay -S cliphist wl-clip-persist nwg-wrapper pacseek topgrade pamac-manager noisetorch rofimoji wtype zeit gh
```

## Notes
Ensure all dependencies are installed to maintain full functionality of the Sway environment, custom scripts, and system integrations.

# Sway Desktop Environment Configuration
## Fonts

The following fonts are essential for system and script functionality:

### Monospace and Programming Fonts
- JetBrains Mono Nerd Font (multiple variants)
- JetBrains Mono NL Nerd Font
- Source Code Pro
- Fira Code

### System Fonts
- Roboto (various weights)
- Roboto Condensed
- Cantarell
- Noto Color Emoji

### Additional Fonts
- WenQuanYi Micro Hei (Chinese font)
- FreeSans
- FreeMono
- FreeSerif

### Installation Commands

#### Pacman (Official Repositories)
```bash
sudo pacman -S ttf-jetbrains-mono-nerd ttf-sourcecodepro-nerd ttf-fira-code noto-fonts noto-fonts-emoji ttf-roboto ttf-roboto-mono cantarell-fonts wqy-microhei
```

#### Yay (AUR Packages)
```bash
yay -S nerd-fonts-jetbrains-mono ttf-sourcecodepro-nerd-font-git ttf-nerd-fonts-symbols ttf-free
```

## Notes
Ensure these fonts are installed to maintain proper rendering in terminals, IDEs, and system interfaces.
