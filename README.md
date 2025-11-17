# Milo's Dotfiles

Personal configuration files for **CachyOS/Arch Linux** with **Sway WM**.

## What's Included

- **Sway** - Tiling Wayland compositor with custom keybindings
- **Waybar** - Feature-rich status bar with custom modules
- **Rofi** - Application launcher and window switcher
- **Foot** - Fast Wayland terminal
- **40+ custom scripts** - Screenshot, recording, theming, USB management, etc.
- **Multiple themes** - Catppuccin (4 variants), Dracula, Nordic, Matcha
- **Shell configs** - Zsh with Powerlevel10k, Bash, aliases, vim

## Quick Start

### Fresh CachyOS/Arch Install

```bash
# Download and run the installer
curl -sL https://raw.githubusercontent.com/milojarow/dotfiles/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The installer will:
1. Check system compatibility
2. Install `paru` (AUR helper) if needed
3. Install core dependencies
4. Clone dotfiles as a bare repository
5. Deploy files to `$HOME`
6. Backup any conflicting files
7. Set correct permissions
8. Let you choose a theme

### Manual Installation

```bash
# 1. Install paru (if not already installed)
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si

# 2. Clone as bare repository
git clone --bare git@github.com:milojarow/dotfiles.git ~/.dotfiles

# 3. Define alias (add to .bashrc or .zshrc for persistence)
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'

# 4. Checkout files (backup conflicts first if needed)
dots checkout

# 5. Hide untracked files from status
dots config status.showUntrackedFiles no

# 6. Install dependencies
paru -S --needed $(grep -v '^#' ~/.dependencies | grep -v '^\s*$' | tr '\n' ' ')

# 7. Make scripts executable
chmod +x ~/.config/sway/scripts/*.sh ~/.config/sway/scripts/*.py ~/.scripts/*
```

## Structure

```
~
├── .aliases                    # Shell aliases including 'dots'
├── .bashrc                     # Bash configuration
├── .zshrc                      # Zsh configuration
├── .p10k.zsh                   # Powerlevel10k theme
├── .vimrc                      # Vim configuration
├── .gitconfig                  # Git settings
├── .dependencies               # Core package list (read by install.sh)
├── .dependencies-optional      # Optional packages for extra features
├── .config/
│   ├── sway/
│   │   ├── config             # Main sway config
│   │   ├── config.d/          # Modular config files
│   │   ├── modes/             # Sway modes (resize, screenshot, etc.)
│   │   ├── scripts/           # 40+ custom scripts
│   │   ├── themes/            # Theme definitions + packages
│   │   └── inputs/            # Input device configs
│   ├── waybar/
│   │   ├── config.jsonc       # Waybar modules
│   │   └── style.css          # Waybar styling
│   ├── rofi/                   # Rofi launcher themes
│   ├── mako/                   # Notification daemon config
│   ├── swaylock/               # Lock screen config
│   ├── swayidle/               # Idle behavior config
│   └── nwg-wrapper/            # Cheatsheet overlay
├── .scripts/                   # Personal scripts
└── .local/bin/                 # User binaries
```

## Cheatsheet

Press **`Mod + /`** to toggle the on-screen cheatsheet.

### Essential Keybindings

| Action | Binding |
|--------|---------|
| Toggle Cheatsheet | `Mod + /` |
| Command Finder | `Mod + ?` |
| Terminal | `Mod + Return` |
| Floating Terminal | `Mod + Shift + Return` |
| App Launcher | `Mod + D` |
| Window Switcher | `Mod + P` |
| Kill Window | `Mod + Shift + Q` |
| Lock Screen | `Mod + X` |
| Reload Config | `Mod + Shift + C` |
| Emoji Picker | `Mod + .` |

### Modes

| Mode | Activation |
|------|------------|
| Screenshot | `Print` |
| Recording | `Mod + Shift + R` |
| Resize | `Mod + R` |
| Swap Windows | `Mod + Ctrl + W` |
| Power Menu | `Mod + Shift + E` |

## Managing Dotfiles

The dotfiles are managed as a bare git repository. Use the `dots` alias:

```bash
# Check status
dots status

# Add changes
dots add ~/.config/sway/config

# Commit
dots commit -m "Update sway config"

# Push to remote
dots push

# Pull updates
dots pull
```

### Adding New Dependencies

When you install a new tool that your configs depend on:

1. Add the package name to `~/.dependencies`
2. Commit and push:
   ```bash
   dots add ~/.dependencies
   dots commit -m "Add new-package to dependencies"
   dots push
   ```

The `install.sh` will automatically pick up new dependencies on fresh installs.

## Themes

Available themes in `.config/sway/themes/`:

- **Catppuccin** (Mocha, Macchiato, Frappe, Latte)
- **Dracula**
- **Nordic Bluish Accent**
- **Matcha** (Green, Blue, Red, Leaf)

Each theme has:
- `theme.conf` - Color definitions for sway
- `foot-theme.ini` - Terminal colors
- `packages` - GTK themes, icon packs, fonts

To change theme manually:
```bash
# Edit sway config
vim ~/.config/sway/config

# Change the include line to your preferred theme:
include ~/.config/sway/themes/catppuccin-mocha/theme.conf

# Install theme packages
paru -S --needed $(cat ~/.config/sway/themes/catppuccin-mocha/packages)

# Reload sway
swaymsg reload
```

## Custom Scripts

Located in `~/.config/sway/scripts/`:

- **lock.sh** - Blur screen and lock
- **screenshot-*.sh** - Screenshot utilities
- **recorder.sh** - Screen recording with wf-recorder
- **usb-monitor.sh** - USB device management
- **weather.py** - Weather widget for waybar
- **theme-toggle.sh** - Light/dark theme switching
- **sunset.sh** - Blue light filter (wlsunset)
- **wluma.sh** - Adaptive brightness
- **dnd.sh** - Do Not Disturb toggle
- **valent.py** - Phone integration (KDE Connect)

## Optional Features

Install enhanced features:

```bash
# GitHub notifications in waybar
paru -S github-cli
gh auth login

# Phone integration
paru -S valent

# Night light
paru -S wlsunset

# Adaptive brightness
paru -S wluma

# All optional packages
paru -S --needed $(grep -v '^#' ~/.dependencies-optional | grep -v '^\s*$' | tr '\n' ' ')
```

## Troubleshooting

### Waybar modules not working
```bash
# Check if required tools are installed
command -v playerctl   # Media controls
command -v cliphist    # Clipboard
command -v gh          # GitHub notifications
```

### Scripts not executing
```bash
# Fix permissions
chmod +x ~/.config/sway/scripts/*.sh
chmod +x ~/.config/sway/scripts/*.py
```

### Fonts/icons not displaying
```bash
# Install nerd fonts
paru -S ttf-jetbrains-mono-nerd ttf-font-awesome
```

### After updating dotfiles
```bash
# Pull latest changes
dots pull

# Fix permissions on new scripts
chmod +x ~/.config/sway/scripts/*

# Install any new dependencies
paru -S --needed $(grep -v '^#' ~/.dependencies | grep -v '^\s*$' | tr '\n' ' ')

# Reload sway
swaymsg reload
```

## Credits

- Inspired by [Manjaro Sway](https://github.com/Manjaro-Sway/manjaro-sway)
- Catppuccin theme from [catppuccin/catppuccin](https://github.com/catppuccin/catppuccin)
- Bare repo technique from [Atlassian dotfiles tutorial](https://www.atlassian.com/git/tutorials/dotfiles)

## License

Personal configuration files. Use at your own risk.
