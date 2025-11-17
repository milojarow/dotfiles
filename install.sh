#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="git@github.com:milojarow/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check if we're on Arch-based system
check_system() {
    info "Checking system compatibility..."

    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/cachyos-release ]]; then
        error "This script is designed for Arch-based systems (Arch, CachyOS, Manjaro, etc.)"
        exit 1
    fi

    if ! command -v pacman &> /dev/null; then
        error "pacman not found. Are you sure this is Arch-based?"
        exit 1
    fi

    success "System check passed"
}

# Install paru if not present
ensure_paru() {
    if command -v paru &> /dev/null; then
        success "paru is already installed"
        return 0
    fi

    info "Installing paru (AUR helper)..."

    # Ensure base-devel and git are installed
    sudo pacman -S --needed --noconfirm base-devel git

    # Clone and build paru
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf "$temp_dir"

    success "paru installed successfully"
}

# Read dependencies from file, ignoring comments and empty lines
read_dependencies() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep -v '^\s*#' "$file" | grep -v '^\s*$' | tr '\n' ' '
    fi
}

# Install packages from .dependencies file
install_core_dependencies() {
    info "Installing core dependencies..."

    # First check if .dependencies exists in the current directory (for fresh installs)
    # If not, we'll clone the repo first and then install
    local deps_file=""

    if [[ -f "$HOME/.dependencies" ]]; then
        deps_file="$HOME/.dependencies"
    elif [[ -f "./.dependencies" ]]; then
        deps_file="./.dependencies"
    else
        warn "No .dependencies file found. Skipping core package installation."
        warn "After dotfiles are deployed, run: paru -S --needed \$(grep -v '^#' ~/.dependencies | grep -v '^\s*$' | tr '\\n' ' ')"
        return 0
    fi

    local packages
    packages=$(read_dependencies "$deps_file")

    if [[ -n "$packages" ]]; then
        info "Installing packages: $packages"
        # shellcheck disable=SC2086
        paru -S --needed --noconfirm $packages || {
            warn "Some packages may have failed to install. Check the output above."
        }
        success "Core dependencies installed"
    fi
}

# Install theme-specific packages
install_theme_packages() {
    local theme_dir="$HOME/.config/sway/themes"

    if [[ ! -d "$theme_dir" ]]; then
        warn "Theme directory not found. Skipping theme package installation."
        return 0
    fi

    info "Available themes:"
    local themes=()
    local i=1
    for theme in "$theme_dir"/*/; do
        if [[ -d "$theme" ]]; then
            theme_name=$(basename "$theme")
            themes+=("$theme_name")
            echo "  $i) $theme_name"
            ((i++))
        fi
    done

    echo "  0) Skip theme installation"
    echo ""
    read -rp "Select theme to install packages for (0-$((i-1))): " choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        info "Skipping theme installation"
        return 0
    fi

    if [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$i" ]]; then
        local selected_theme="${themes[$((choice-1))]}"
        local packages_file="$theme_dir/$selected_theme/packages"

        if [[ -f "$packages_file" ]]; then
            info "Installing packages for $selected_theme theme..."
            local theme_packages
            theme_packages=$(read_dependencies "$packages_file")
            # shellcheck disable=SC2086
            paru -S --needed --noconfirm $theme_packages || {
                warn "Some theme packages may have failed to install."
            }
            success "Theme packages installed"

            # Update sway config to use selected theme
            info "Updating sway config to use $selected_theme theme..."
            local sway_config="$HOME/.config/sway/config"
            if [[ -f "$sway_config" ]]; then
                # Replace the theme include line
                sed -i "s|include ~/.config/sway/themes/.*/theme.conf|include ~/.config/sway/themes/$selected_theme/theme.conf|" "$sway_config"
                success "Sway configured to use $selected_theme theme"
            fi
        else
            warn "No packages file found for $selected_theme"
        fi
    else
        warn "Invalid selection. Skipping theme installation."
    fi
}

# Setup the bare git repository
setup_bare_repo() {
    info "Setting up dotfiles bare repository..."

    if [[ -d "$DOTFILES_DIR" ]]; then
        warn "Dotfiles directory already exists at $DOTFILES_DIR"
        read -rp "Do you want to update from remote? [y/N]: " update_choice
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" fetch origin
            git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" reset --hard origin/main
            success "Dotfiles updated from remote"
        fi
        return 0
    fi

    # Clone bare repository
    info "Cloning dotfiles repository..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

    success "Bare repository cloned to $DOTFILES_DIR"
}

# Backup conflicting files before checkout
backup_conflicts() {
    info "Checking for file conflicts..."

    local conflicts
    conflicts=$(git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>&1 | grep "^\s*\." | awk '{print $1}' || true)

    if [[ -n "$conflicts" ]]; then
        warn "Found conflicting files. Creating backup..."
        mkdir -p "$BACKUP_DIR"

        echo "$conflicts" | while read -r file; do
            if [[ -n "$file" ]] && [[ -e "$HOME/$file" ]]; then
                # Create directory structure in backup
                local backup_path="$BACKUP_DIR/$file"
                mkdir -p "$(dirname "$backup_path")"
                mv "$HOME/$file" "$backup_path"
                info "Backed up: $file"
            fi
        done

        success "Conflicting files backed up to $BACKUP_DIR"
    else
        success "No file conflicts found"
    fi
}

# Checkout the dotfiles
checkout_dotfiles() {
    info "Deploying dotfiles..."

    # Try checkout, if fails backup conflicts and retry
    if ! git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>/dev/null; then
        backup_conflicts
        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout
    fi

    # Configure git to ignore untracked files
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

    success "Dotfiles deployed successfully"
}

# Make all scripts executable
fix_permissions() {
    info "Setting executable permissions on scripts..."

    # Find all shell scripts and Python files
    local script_dirs=(
        "$HOME/.config/sway/scripts"
        "$HOME/.scripts"
        "$HOME/.local/bin"
    )

    for dir in "${script_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f \( -name "*.sh" -o -name "*.py" -o ! -name "*.*" \) -exec chmod +x {} \;
            info "Made scripts executable in $dir"
        fi
    done

    # Specific files that need to be executable
    [[ -f "$HOME/.scripts/clipardo" ]] && chmod +x "$HOME/.scripts/clipardo"

    success "Permissions fixed"
}

# Show post-install instructions
show_post_install() {
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}    Installation Complete!           ${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Add the dots alias to your current session:"
    echo "   source ~/.aliases"
    echo ""
    echo "2. Log out and select 'Sway' as your session"
    echo ""
    echo "3. Once in Sway, press ${BLUE}Mod+/${NC} to show the cheatsheet"
    echo ""
    echo "4. Install optional packages for extra features:"
    echo "   paru -S --needed \$(grep -v '^#' ~/.dependencies-optional | grep -v '^\s*\$' | tr '\\n' ' ')"
    echo ""

    if [[ -d "$BACKUP_DIR" ]]; then
        echo "Backup of your previous dotfiles: $BACKUP_DIR"
        echo ""
    fi

    echo "Useful commands:"
    echo "  dots status  - Check dotfiles status"
    echo "  dots add     - Stage changes"
    echo "  dots commit  - Commit changes"
    echo "  dots push    - Push to remote"
    echo ""
}

# Main installation flow
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║      Milo's Dotfiles Installer         ║"
    echo "║         CachyOS / Arch Linux           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    check_system
    ensure_paru

    echo ""
    read -rp "Install core dependencies before cloning? [Y/n]: " install_deps
    if [[ ! "$install_deps" =~ ^[Nn]$ ]]; then
        # For fresh install, we need to fetch the deps file first
        if [[ ! -f "$HOME/.dependencies" ]]; then
            info "Fetching dependency list from repository..."
            curl -sL "https://raw.githubusercontent.com/milojarow/dotfiles/main/.dependencies" -o /tmp/.dependencies
            if [[ -f /tmp/.dependencies ]]; then
                cp /tmp/.dependencies ./.dependencies
                install_core_dependencies
                rm -f ./.dependencies /tmp/.dependencies
            else
                warn "Could not fetch dependency list. Will install after checkout."
            fi
        else
            install_core_dependencies
        fi
    fi

    setup_bare_repo
    checkout_dotfiles
    fix_permissions

    echo ""
    read -rp "Install theme-specific packages? [Y/n]: " install_theme
    if [[ ! "$install_theme" =~ ^[Nn]$ ]]; then
        install_theme_packages
    fi

    # Source aliases for this session
    if [[ -f "$HOME/.aliases" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.aliases"
        success "Aliases loaded"
    fi

    show_post_install
}

# Run main function
main "$@"
