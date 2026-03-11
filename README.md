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
# Download and run the installer (DO NOT use sudo)
curl -sL https://raw.githubusercontent.com/milojarow/dotfiles/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

> **Important:** Run as your normal user, NOT with sudo. The script calls sudo internally when needed. Running with sudo would deploy dotfiles to `/root/` instead of your home directory.

The installer runs **19 steps** and covers the full setup automatically:

| # | Step |
|---|------|
| 1 | System compatibility check (Arch/CachyOS) |
| 2 | Internet connectivity check (retries automatically) |
| 3 | Disk space check (≥ 5 GB) |
| 4 | Install `paru` AUR helper |
| 5 | Fetch dependency list from repository |
| 6 | Install core packages from `.dependencies` |
| 7 | Clone dotfiles bare repo (HTTPS) |
| 8 | Deploy all config files to `$HOME` (backs up conflicts) |
| 9 | Configure git bare repo |
| 10 | Set executable permissions on all scripts |
| 11 | Install Rust toolchain via rustup |
| 12 | Build and install `eww` widget daemon |
| 13 | Create required runtime directories (`~/unzipper`, etc.) |
| 14 | Reload systemd user daemon |
| 15 | Enable and start non-Wayland services |
| 16 | Enable Wayland session services (waybar, eww, etc.) |
| 17 | Create pacman hooks |
| 18 | Set default shell to fish |
| 19 | Index user man pages |

**If the installer is interrupted**, just re-run it — it resumes from the last completed step automatically.

#### After the installer finishes

```bash
# Switch dotfiles remote back to SSH (required for pushing)
git --git-dir=~/.dotfiles remote set-url origin git@github.com:milojarow/dotfiles.git

# Log out and select 'Sway' as your session
```

### Manual Installation

```bash
# 1. Install paru (if not already installed)
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si

# 2. Clone as bare repository (HTTPS — no SSH keys required)
git clone --bare https://github.com/milojarow/dotfiles.git ~/.dotfiles

# 3. Define alias (add to .bashrc or .zshrc for persistence)
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'

# 4. Checkout files (backup conflicts first if needed)
dots checkout

# 5. Hide untracked files from status
dots config status.showUntrackedFiles no

# 6. Install dependencies
paru -S --needed $(grep -v '^#' ~/.dependencies | grep -v '^\s*$' | tr '\n' ' ')

# 7. Make scripts executable
chmod +x ~/.config/sway/scripts/*.sh ~/.config/sway/scripts/*.py \
         ~/.config/eww/scripts/*.sh ~/.scripts/* ~/.local/bin/*

# 8. Create required directories
mkdir -p ~/unzipper ~/.local/share/man/man1

# 9. Enable systemd services
systemctl --user daemon-reload
systemctl --user enable --now bt-audio-watchdog.service audio-tracker.service unzipper.service
systemctl --user enable eww.service eww-resume.service waybar.service \
          screenshot-notify.service screenshot-clipboard-notify.service

# 10. Set default shell to fish
chsh -s /usr/bin/fish

# 11. Index user man pages
mandb --user-db
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
│   ├── eww/                    # Elkowar's Wacky Widgets (cheatsheet overlay, activate-linux, etc.)
│   └── nwg-wrapper/            # Cheatsheet pango content files (left/right columns)
├── .scripts/                   # Personal scripts
└── .local/bin/                 # User binaries
```

## Cheatsheet

Press **`Mod + /`** to toggle the on-screen cheatsheet (fullscreen overlay powered by eww).

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
# Bluetooth TUI manager
paru -S bluetuith

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

## System Services

After installation, enable services required for full functionality:

```bash
# Bluetooth
sudo systemctl enable --now bluetooth.service
```

### Bluetooth Audio (WirePlumber)

The file `.config/wireplumber/wireplumber.conf.d/50-bluetooth-config.conf` forces A2DP
(high-quality audio only) and disables HFP/HSP for a specific speaker, identified by MAC address.

If you have a different device (or no such device), either delete the file or update the
`device.name` field to match your hardware:

```bash
# List paired devices and their MAC addresses
bluetoothctl devices
# Example output: Device 44:1D:B1:4B:0B:A0 DEA700
# → device.name = "~bluez_card.44_1D_B1_4B_0B_A0"  (colons replaced by underscores)
```

## Pacman Hooks

These hooks live in `/etc/pacman.d/hooks/` and are **not** tracked in the dotfiles repo — create them manually on a fresh install.

### `waybar-pacman.hook`
Refreshes the waybar pacman module after any pacman operation.
```ini
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Refreshing waybar pacman module...
When = PostTransaction
Exec = /usr/bin/pkill -RTMIN+14 waybar
```

### `python-rebuild-nwg-wrapper.hook`
Rebuilds nwg-wrapper when Python is upgraded to avoid metadata breakage.
```ini
[Trigger]
Operation = Upgrade
Type = Package
Target = python

[Action]
Description = Rebuilding nwg-wrapper for new Python version...
When = PostTransaction
Exec = /usr/bin/sudo -u milo /usr/bin/paru -S --rebuild nwg-wrapper --noconfirm
NeedsTargets
```

### `cargo-update.hook`
Updates all cargo-installed binaries (eww, cargo-update, etc.) after every upgrade.
Requires `cargo-update` crate: `cargo install cargo-update`
```ini
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Updating cargo-installed binaries...
When = PostTransaction
Exec = /usr/bin/sudo -u milo /home/milo/.cargo/bin/cargo install-update -a
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

# Index user man pages (if new .1 files were added under ~/.local/share/man/)
mandb --user-db

# Reload sway
swaymsg reload
```

## Credits

- Inspired by [Manjaro Sway](https://github.com/Manjaro-Sway/manjaro-sway)
- Catppuccin theme from [catppuccin/catppuccin](https://github.com/catppuccin/catppuccin)
- Bare repo technique from [Atlassian dotfiles tutorial](https://www.atlassian.com/git/tutorials/dotfiles)

## License

Personal configuration files. Use at your own risk.
