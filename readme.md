# Milo's Dotfiles

Welcome to my dotfiles repository! Here, you'll find a collection of configuration files and scripts I use to personalize my Arch Linux environment. This repository serves as a way to backup, share, and quickly set up my working environment on new installations.

## Overview of Contents

- `.Xresources`: Contains color schemes for X resources.
- `.bashrc`: Custom aliases, environment variables, and scripts for my shell.
- `.inputrc`: Configurations for terminal behavior, set to Vim mode with additional modifications.
- `.vimrc`: My Vim editor configurations and customizations.
- `.xbindkeysrc`: Custom keybindings, including a script to switch between keyboard layouts. More bindings will be added over time.
- `.xinitrc.ignore`: A backup file for starting X sessions in emergency situations. Rename to `.xinitrc` if needed.
- `.xprofile`: Used to start window manager, picom, eww, etc.
- `.xorg.conf.d`: Directory containing `10-amdgpu.conf`, `10-quirks.conf`, and `40-libinput.conf`. These are intended to be placed in `/etc/X11/xorg.conf.d/`.
- `.scripts`: A collection of custom scripts. Includes `clipardo` for copying files to clipboard and `shot.sh` for partial screenshots.
- `vimwiki`: Contains markdown files with notes, tips, tricks, and guides.
- `.config`: Various configuration files including `starship.toml` for custom prompt, `picom.conf` for picom, and configurations for LeftWM.

## Dependencies

To fully utilize these dotfiles, the following packages are necessary:

- dbus
- `[xbindkeys](xbindkeys)`
- `picom`
- `openssh`
- `dunst`
- `feh` 
- `hacksaw`, `shotgun`, and `xclip` (for the `shot.sh` script)

Additionally, the following packages need to be installed from their respective git repositories:

- `eww` (Elkowar's Wacky Widgets)
- `paru` (AUR helper)
- `leftwm-themes`

## Installation

**Note:** An installation script/PKGBUILD is currently in progress, which will automate the setup process on a fresh Arch Linux installation. This will include the placement of configuration files and installation of dependencies.

## Contributing

Feel free to fork this repository and customize it to your liking. Contributions, suggestions, and improvements are welcome.

## License

This repository is licensed under the MIT License - see the LICENSE file for details.

