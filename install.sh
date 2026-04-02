#!/usr/bin/env bash
# Re-exec in bash if running from another shell (fish, zsh, dash, etc.)
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"

set -euo pipefail

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
DOTFILES_REPO="https://github.com/milojarow/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
CHECKPOINT_FILE="$HOME/.dotfiles-install.checkpoint"
BACKUP_DIR=""   # Set once in main() with a timestamp
TOTAL_STEPS=20

# ── COLORS & SYMBOLS ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SYM_OK='✓'
SYM_RUN='→'
SYM_SKIP='·'
SYM_WARN='⚠'
SYM_FAIL='✗'

# ── CURRENT STEP TRACKING (for ERR trap) ──────────────────────────────────────
_STEP_NUM=""
_STEP_DESC=""

# ── OUTPUT FUNCTIONS ──────────────────────────────────────────────────────────
print_banner() {
    echo -e "${BLUE}${BOLD}"
    echo "╔════════════════════════════════════════╗"
    echo "║      Milo's Dotfiles Installer         ║"
    echo "║         CachyOS / Arch Linux           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${BOLD}── $1 ────────────────────────────────────────${NC}"
}

print_step_running() { echo -e "  ${CYAN}${SYM_RUN}${NC} [${1}/${TOTAL_STEPS}] ${2}..."; }
print_step_ok()      { echo -e "  ${GREEN}${SYM_OK}${NC} [${1}/${TOTAL_STEPS}] ${2}"; }
print_step_skip()    { echo -e "  ${BLUE}${SYM_SKIP}${NC} [${1}/${TOTAL_STEPS}] ${2} ${BLUE}(already done)${NC}"; }
print_step_fail()    { echo -e "  ${RED}${SYM_FAIL}${NC} [${1}/${TOTAL_STEPS}] ${2} ${RED}(FAILED)${NC}"; }
print_step_warn()    { echo -e "  ${YELLOW}${SYM_WARN}${NC} [${1}/${TOTAL_STEPS}] ${2} ${YELLOW}(warning — non-fatal)${NC}"; }
info()  { echo -e "    ${BLUE}ℹ${NC}  $1"; }
warn()  { echo -e "    ${YELLOW}${SYM_WARN}${NC}  $1"; }
error() { echo -e "    ${RED}${SYM_FAIL}${NC}  $1" >&2; }

# ── ERR TRAP ──────────────────────────────────────────────────────────────────
_err_handler() {
    local line="$1" cmd="$2"
    echo ""
    if [[ -n "$_STEP_NUM" ]]; then
        print_step_fail "$_STEP_NUM" "$_STEP_DESC"
    fi
    error "Unexpected error on line ${line}: ${cmd}"
    echo ""
    echo "    Re-run install.sh to resume from the last completed step."
    echo ""
    exit 1
}
trap '_err_handler $LINENO "$BASH_COMMAND"' ERR

# ── CHECKPOINT ENGINE ─────────────────────────────────────────────────────────
step_done() { grep -qxF "$1" "$CHECKPOINT_FILE" 2>/dev/null; }
mark_done() { echo "$1" >> "$CHECKPOINT_FILE"; }

# run_step <id> <num> <description> <function>
# Runs <function>, marks it done on success. ERR trap handles failures.
run_step() {
    local id="$1" num="$2" desc="$3" fn="$4"
    if step_done "$id"; then
        print_step_skip "$num" "$desc"
        return 0
    fi
    _STEP_NUM="$num"
    _STEP_DESC="$desc"
    print_step_running "$num" "$desc"
    "$fn"
    mark_done "$id"
    print_step_ok "$num" "$desc"
    _STEP_NUM=""
    _STEP_DESC=""
}

# ── CHECKPOINT / RESUME PROMPT ────────────────────────────────────────────────
handle_checkpoint() {
    [[ ! -f "$CHECKPOINT_FILE" ]] && return 0

    local completed last
    completed=$(wc -l < "$CHECKPOINT_FILE")
    last=$(tail -1 "$CHECKPOINT_FILE")

    echo ""
    echo -e "  ${YELLOW}Checkpoint found${NC}: ${completed} steps completed (last: ${YELLOW}${last}${NC})"
    echo ""
    read -rp "  [R]esume   [F]resh start   [Q]uit: " choice
    case "${choice,,}" in
        f)
            rm -f "$CHECKPOINT_FILE"
            info "Starting fresh..."
            ;;
        q)
            echo "  Aborted."
            exit 0
            ;;
        *)
            info "Resuming..."
            ;;
    esac
}

# ── HELPERS ───────────────────────────────────────────────────────────────────

# Strip comments and blank lines from a deps file, return space-separated list
read_deps() {
    local file="$1"
    [[ -f "$file" ]] && grep -v '^\s*#' "$file" | grep -v '^\s*$' | tr '\n' ' '
}

# ── PRE-FLIGHT ────────────────────────────────────────────────────────────────
step_preflight_not_root() {
    # Always-run — never checkpointed
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root. The script calls sudo internally when needed."
        exit 1
    fi
}

step_preflight_arch() {
    if [[ ! -f /etc/arch-release ]] && [[ ! -f /etc/cachyos-release ]]; then
        error "This installer is designed for Arch-based systems (Arch, CachyOS, Manjaro, etc.)"
        return 1
    fi
    if ! command -v pacman &>/dev/null; then
        error "pacman not found — are you sure this is Arch-based?"
        return 1
    fi
}

step_preflight_internet() {
    local timeout=30 elapsed=0
    info "Testing connection to archlinux.org..."
    until curl -fsS --max-time 5 https://archlinux.org >/dev/null 2>&1; do
        (( elapsed++ ))
        if (( elapsed >= timeout )); then
            error "No internet connection after ${timeout}s. Check your network and try again."
            return 1
        fi
        warn "Not connected yet, retrying in 3s... (${elapsed}/${timeout})"
        sleep 3
    done
}

step_preflight_disk() {
    local available_gb
    available_gb=$(df -BG "$HOME" | awk 'NR==2 {gsub("G",""); print $4}')
    if (( available_gb < 5 )); then
        error "Less than 5 GB free on \$HOME partition (${available_gb} GB available)."
        error "Free up space and try again."
        return 1
    fi
    info "Disk space OK: ${available_gb} GB available"
}

# ── BASE TOOLS ────────────────────────────────────────────────────────────────
step_install_paru() {
    if command -v paru &>/dev/null; then
        info "paru already installed"
        return 0
    fi
    info "Installing paru AUR helper..."
    sudo pacman -S --needed --noconfirm base-devel git
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    pushd "$tmpdir/paru" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf "$tmpdir"
}

step_fetch_deps_file() {
    if [[ -f "$HOME/.dependencies" ]]; then
        info ".dependencies already present"
        return 0
    fi
    local url="https://raw.githubusercontent.com/milojarow/dotfiles/main/.dependencies"
    info "Fetching dependency list from repository..."
    if ! curl -fsSL "$url" -o "$HOME/.dependencies"; then
        error "Could not fetch .dependencies from GitHub."
        return 1
    fi
    info "Saved to ~/.dependencies"
}

step_install_core_deps() {
    local packages
    packages=$(read_deps "$HOME/.dependencies")
    if [[ -z "$packages" ]]; then
        warn "~/.dependencies is empty — skipping."
        return 0
    fi
    info "Installing core packages (this may take several minutes)..."
    # shellcheck disable=SC2086
    paru -S --needed --noconfirm $packages || {
        warn "Some packages may have failed. Check the output above — continuing."
    }
}

# ── DOTFILES ──────────────────────────────────────────────────────────────────
step_clone_bare_repo() {
    if [[ -d "$DOTFILES_DIR" ]] && \
       git --git-dir="$DOTFILES_DIR" rev-parse HEAD &>/dev/null; then
        info "Bare repo already exists at $DOTFILES_DIR"
        read -rp "    Pull latest changes? [y/N]: " pull_choice
        if [[ "${pull_choice,,}" == "y" ]]; then
            git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" fetch origin
            git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" reset --hard origin/main
            info "Updated from remote"
        fi
        return 0
    fi
    info "Cloning dotfiles (HTTPS)..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
}

step_checkout_dotfiles() {
    # Try a clean checkout first
    if git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>/dev/null; then
        return 0
    fi

    # Backup conflicting files, then retry
    info "Backing up conflicting files to $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"
    local conflicts
    conflicts=$(git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>&1 \
        | grep '^\s' | awk '{print $1}')
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if [[ -e "$HOME/$file" ]]; then
            local dest="$BACKUP_DIR/$file"
            mkdir -p "$(dirname "$dest")"
            mv "$HOME/$file" "$dest"
        fi
    done <<< "$conflicts"
    info "Conflicts backed up to: $BACKUP_DIR"

    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout
}

step_configure_bare_repo() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" \
        config status.showUntrackedFiles no
}

step_fix_permissions() {
    local dirs=(
        "$HOME/.config/sway/scripts"
        "$HOME/.scripts"
        "$HOME/.local/bin"
        "$HOME/.config/eww/scripts"
    )
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -type f \
            \( -name "*.sh" -o -name "*.py" -o ! -name "*.*" \) \
            -exec chmod +x {} \;
    done
    [[ -f "$HOME/.scripts/clipardo" ]] && chmod +x "$HOME/.scripts/clipardo"
}

# ── BUILD TOOLS ───────────────────────────────────────────────────────────────
step_install_rust() {
    if command -v cargo &>/dev/null; then
        info "Rust/cargo already installed"
        return 0
    fi
    info "Installing Rust via rustup..."
    sudo pacman -S --needed --noconfirm rustup
    rustup toolchain install stable
    # Source cargo env for the remainder of this session
    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
}

step_install_eww() {
    if [[ -f "$HOME/.cargo/bin/eww" ]]; then
        info "eww already installed at ~/.cargo/bin/eww"
        return 0
    fi
    info "Building eww from AUR (5–15 minutes — go grab a coffee)..."
    info "Watch build progress: journalctl --user -f"
    # Non-fatal: paru failure is caught and downgraded to a warning
    if ! paru -S --needed --noconfirm eww 2>&1 | tee /tmp/eww-build.log; then
        warn "eww build failed. Build log: /tmp/eww-build.log"
        warn "Install manually later: paru -S eww"
        return 0   # Non-fatal — do NOT propagate failure
    fi
    if [[ ! -f "$HOME/.cargo/bin/eww" ]]; then
        warn "paru succeeded but eww binary not found at ~/.cargo/bin/eww"
        warn "Install manually: paru -S eww"
    fi
}

# eww uses a custom checkpoint: only mark done if the binary actually exists
_run_eww_step() {
    if step_done "install_eww"; then
        print_step_skip 12 "eww widget daemon"
        return 0
    fi
    _STEP_NUM=12
    _STEP_DESC="eww widget daemon"
    print_step_running 12 "eww widget daemon"
    step_install_eww
    _STEP_NUM=""
    _STEP_DESC=""
    if [[ -f "$HOME/.cargo/bin/eww" ]]; then
        mark_done "install_eww"
        print_step_ok 12 "eww widget daemon"
    else
        print_step_warn 12 "eww widget daemon"
    fi
}

# ── SYSTEM INTEGRATION ────────────────────────────────────────────────────────
step_create_dirs() {
    # ~/unzipper: inotifywait crashes if the directory doesn't exist at service start
    mkdir -p "$HOME/unzipper"
    info "Created: ~/unzipper"

    # ~/.local/share/man/man1: may not exist on a fresh Arch install
    mkdir -p "$HOME/.local/share/man/man1"
    info "Created: ~/.local/share/man/man1"
}

step_systemd_reload() {
    systemctl --user daemon-reload
}

step_systemd_enable_start() {
    # Services that do NOT need a Wayland display — enable and start now
    local services=(
        bt-audio-watchdog.service
        audio-tracker.service
        unzipper.service
    )
    for svc in "${services[@]}"; do
        if [[ ! -f "$HOME/.config/systemd/user/$svc" ]]; then
            warn "Service file not found, skipping: $svc"
            continue
        fi
        if systemctl --user enable --now "$svc" 2>/dev/null; then
            info "Enabled and started: $svc"
        else
            warn "Could not enable+start $svc (non-fatal)"
        fi
    done
}

step_systemd_enable_only() {
    # Services that need a Wayland session — enable only; sway starts them
    local services=(
        eww.service
        eww-resume.service
        waybar.service
        screenshot-notify.service
        screenshot-clipboard-notify.service
        s45-panel.service        # ExecStartPre polls kubectl — enable-only is safe
        etesync-web.service      # Needs ~/.local/lib/etesync-web built first
    )
    for svc in "${services[@]}"; do
        if [[ ! -f "$HOME/.config/systemd/user/$svc" ]]; then
            warn "Service file not found, skipping: $svc"
            continue
        fi
        if systemctl --user enable "$svc" 2>/dev/null; then
            info "Enabled (starts with Wayland session): $svc"
        else
            warn "Could not enable $svc (non-fatal)"
        fi
    done
}

step_create_pacman_hooks() {
    sudo mkdir -p /etc/pacman.d/hooks

    local hook

    # waybar-pacman.hook — refresh waybar pacman module after any transaction
    hook=/etc/pacman.d/hooks/waybar-pacman.hook
    if [[ ! -f "$hook" ]]; then
        sudo tee "$hook" > /dev/null << 'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Refreshing waybar pacman module...
When = PostTransaction
Exec = /bin/sh -c "pkill -RTMIN+14 waybar; exit 0"
EOF
        info "Created: waybar-pacman.hook"
    else
        info "Already exists: waybar-pacman.hook"
    fi

    # cargo-update.hook — keep cargo-installed binaries current after upgrades
    hook=/etc/pacman.d/hooks/cargo-update.hook
    if [[ ! -f "$hook" ]]; then
        sudo tee "$hook" > /dev/null << EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Updating cargo-installed binaries...
When = PostTransaction
Exec = /usr/bin/sudo -u ${USER} ${HOME}/.cargo/bin/cargo install-update -a
EOF
        info "Created: cargo-update.hook"
    else
        info "Already exists: cargo-update.hook"
    fi

    # python-rebuild-nwg-wrapper.hook — rebuild nwg-wrapper on Python upgrades
    hook=/etc/pacman.d/hooks/python-rebuild-nwg-wrapper.hook
    if [[ ! -f "$hook" ]]; then
        sudo tee "$hook" > /dev/null << EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = python

[Action]
Description = Rebuilding nwg-wrapper for new Python version...
When = PostTransaction
Exec = /usr/bin/sudo -u ${USER} /usr/bin/paru -S --rebuild nwg-wrapper --noconfirm
NeedsTargets
EOF
        info "Created: python-rebuild-nwg-wrapper.hook"
    else
        info "Already exists: python-rebuild-nwg-wrapper.hook"
    fi

    # neutralize-birthdate.hook — neutralize systemd userdb birthDate after updates
    hook=/etc/pacman.d/hooks/neutralize-birthdate.hook
    if [[ ! -f "$hook" ]]; then
        sudo tee "$hook" > /dev/null << EOF
# Part of: neutralize-birthdate — systemd userdb birthDate neutralization
# See: man neutralize-birthdate(1)
# Related files:
#   ~/.scripts/neutralize-birthdate.sh                  (core script)
#   /etc/systemd/system/neutralize-birthdate.service    (oneshot service)
#   /etc/systemd/system/neutralize-birthdate.path       (inotify watcher)

[Trigger]
Operation = Upgrade
Operation = Install
Type = Package
Target = systemd
Target = systemd-libs

[Action]
Description = Neutralizing birthDate in userdb records after systemd update...
When = PostTransaction
Exec = ${HOME}/.scripts/neutralize-birthdate.sh
EOF
        info "Created: neutralize-birthdate.hook"
    else
        info "Already exists: neutralize-birthdate.hook"
    fi

    # NVIDIA-specific hooks — only created if NVIDIA GPU is detected
    if lspci | grep -qi 'nvidia'; then

        # nvidia-update-notify.hook — flag NVIDIA driver updates for user notification
        hook=/etc/pacman.d/hooks/nvidia-update-notify.hook
        if [[ ! -f "$hook" ]]; then
            sudo tee "$hook" > /dev/null << 'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Type = Package
Target = nvidia-580xx-dkms
Target = nvidia-580xx-utils
Target = lib32-nvidia-580xx-utils

[Action]
Description = NVIDIA driver updated — flagging for user notification on next login
When = PostTransaction
Exec = /usr/bin/touch /tmp/nvidia-module-update-pending
EOF
            info "Created: nvidia-update-notify.hook"
        else
            info "Already exists: nvidia-update-notify.hook"
        fi

        # prime-run-desktop.hook — re-apply prime-run to .desktop launchers after updates
        hook=/etc/pacman.d/hooks/prime-run-desktop.hook
        if [[ ! -f "$hook" ]]; then
            sudo tee "$hook" > /dev/null << EOF
[Trigger]
Operation = Upgrade
Operation = Install
Type = Package
Target = steam
Target = gimp

[Action]
Description = Re-applying prime-run to .desktop launchers
When = PostTransaction
Exec = /usr/bin/runuser -u ${USER} -- ${HOME}/.scripts/prime-run-desktop-patch.sh
EOF
            info "Created: prime-run-desktop.hook"
        else
            info "Already exists: prime-run-desktop.hook"
        fi

    else
        info "No NVIDIA GPU detected — skipping NVIDIA hooks"
    fi
}

step_set_default_shell() {
    local fish_path="/usr/bin/fish"
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [[ "$current_shell" == "$fish_path" ]] || [[ "$current_shell" == "/bin/fish" ]]; then
        info "Default shell is already fish"
        return 0
    fi

    if ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
        warn "fish not found in /etc/shells yet."
        warn "Run 'chsh -s /usr/bin/fish' manually after installation."
        return 0   # Non-fatal
    fi

    chsh -s "$fish_path"
    info "Default shell set to fish (takes effect on next login)"
}

step_mandb_user() {
    mandb --user-db 2>/dev/null || warn "mandb --user-db failed (non-fatal)"
}

_run_bluetooth() {
    # Bonus step — not numbered, non-fatal
    echo ""
    info "Enabling Bluetooth service..."
    if sudo systemctl enable --now bluetooth.service 2>/dev/null; then
        echo -e "  ${GREEN}${SYM_OK}${NC}  bluetooth.service enabled and started"
    else
        warn "Could not enable bluetooth.service (no hardware, or already enabled)"
    fi
}

# ── CUSTOMIZATION: THEME SELECTION ────────────────────────────────────────────
# Not checkpointed — always offered so the user can change themes anytime
step_select_theme() {
    local theme_dir="$HOME/.config/sway/themes"
    if [[ ! -d "$theme_dir" ]]; then
        warn "Theme directory not found — skipping theme selection."
        return 0
    fi

    print_section "CUSTOMIZATION"
    echo ""
    local themes=() i=1
    for theme in "$theme_dir"/*/; do
        [[ -d "$theme" ]] || continue
        themes+=("$(basename "$theme")")
        echo "    $i) $(basename "$theme")"
        (( i++ ))
    done
    echo "    0) Skip"
    echo ""
    read -rp "  Select theme (0-$((i-1))): " choice

    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        info "Skipping theme installation"
        return 0
    fi

    if (( choice >= 1 && choice < i )); then
        local selected="${themes[$((choice-1))]}"
        local pkgs_file="$theme_dir/$selected/packages"
        if [[ -f "$pkgs_file" ]]; then
            local pkgs
            pkgs=$(read_deps "$pkgs_file")
            info "Installing packages for theme: $selected..."
            # shellcheck disable=SC2086
            paru -S --needed --noconfirm $pkgs || warn "Some theme packages may have failed."
        else
            warn "No packages file for theme: $selected"
        fi

        local sway_config="$HOME/.config/sway/config"
        if [[ -f "$sway_config" ]]; then
            sed -i \
                "s|include ~/.config/sway/themes/.*/theme.conf|include ~/.config/sway/themes/$selected/theme.conf|" \
                "$sway_config"
            info "Sway configured to use theme: $selected"
        fi
    else
        warn "Invalid selection — skipping theme"
    fi
}

# ── CLAUDE CODE SKILLS ────────────────────────────────────────────────────────
step_claude_skills() {
    # Install Claude Code CLI if not present
    if command -v claude &>/dev/null || [[ -f "$HOME/.npm-global/bin/claude" ]]; then
        info "Claude Code already installed"
    elif command -v npm &>/dev/null; then
        info "Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code
    else
        warn "npm not found — install Claude Code manually after setup:"
        warn "  npm install -g @anthropic-ai/claude-code"
    fi

    # Verify skills deployed from dotfiles (step 8)
    local skills_dir="$HOME/.claude/skills"
    if [[ ! -d "$skills_dir" ]]; then
        warn "~/.claude/skills/ not found — check dotfiles checkout (step 8)"
        return 0   # Non-fatal
    fi

    local eww_count sway_count
    eww_count=$(ls -d "$skills_dir"/eww-* 2>/dev/null | wc -l)
    sway_count=$(ls -d "$skills_dir"/sway-* "$skills_dir"/swaylock \
        "$skills_dir"/swayidle "$skills_dir"/swaybg \
        "$skills_dir"/swayr "$skills_dir"/swayimg 2>/dev/null | wc -l)

    if (( eww_count + sway_count == 0 )); then
        warn "No eww/sway skills found — check dotfiles checkout (step 8)"
        return 0
    fi

    info "eww skills:  $eww_count directories"
    info "sway skills: $sway_count directories"
    info "Skills load automatically on the next Claude Code session"
}

# ── POST-INSTALL SUMMARY ──────────────────────────────────────────────────────
show_post_install() {
    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}         Installation Complete!               ${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════${NC}"
    echo ""
    echo "  Next steps:"
    echo ""
    echo "  1. Switch dotfiles remote back to SSH (for pushing):"
    echo -e "     ${CYAN}git --git-dir=~/.dotfiles remote set-url origin git@github.com:milojarow/dotfiles.git${NC}"
    echo ""
    echo "  2. Log out and select 'Sway' as your session"
    echo ""
    echo "  3. Once in Sway, press Mod+/ to open the cheatsheet"
    echo ""
    echo "  4. Optional packages (phone integration, night light, etc.):"
    echo -e "     ${CYAN}paru -S --needed \$(grep -v '^#' ~/.dependencies-optional | grep -v '^\s*\$' | tr '\\n' ' ')${NC}"
    echo ""

    # Conditional notes
    local notes=()
    [[ ! -f "$HOME/.cargo/bin/eww" ]] && \
        notes+=("eww was not installed — retry: paru -S eww")
    [[ ! -f "$HOME/.kube/config-hostinger" ]] && \
        notes+=("s45-panel.service needs ~/.kube/config-hostinger to start")
    notes+=("etesync-web.service needs ~/.local/lib/etesync-web/ built before it starts")

    if (( ${#notes[@]} > 0 )); then
        echo "  Notes:"
        for note in "${notes[@]}"; do
            echo "  ${YELLOW}·${NC}  $note"
        done
        echo ""
    fi

    if [[ -d "$BACKUP_DIR" ]]; then
        echo "  Backed-up conflicting files: $BACKUP_DIR"
        echo ""
    fi

    echo "  Dotfiles management (after starting fish):"
    echo "    dots status   dots add <file>   dots commit   dots push"
    echo ""
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    # Set BACKUP_DIR once with a fixed timestamp — stable across the whole run
    BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

    print_banner
    step_preflight_not_root      # Always-run: never checkpointed
    handle_checkpoint

    print_section "PRE-FLIGHT"
    run_step preflight_arch      1  "System compatibility"     step_preflight_arch
    run_step preflight_internet  2  "Internet connectivity"    step_preflight_internet
    run_step preflight_disk      3  "Disk space (≥ 5 GB)"      step_preflight_disk

    print_section "BASE TOOLS"
    run_step install_paru        4  "AUR helper (paru)"        step_install_paru
    run_step fetch_deps_file     5  "Dependency list"          step_fetch_deps_file
    run_step install_core_deps   6  "Core packages"            step_install_core_deps

    print_section "DOTFILES"
    run_step clone_bare_repo     7  "Clone dotfiles (HTTPS)"   step_clone_bare_repo
    run_step checkout_dotfiles   8  "Deploy dotfiles"          step_checkout_dotfiles
    run_step configure_bare_repo 9  "Configure git"            step_configure_bare_repo
    run_step fix_permissions     10 "Script permissions"       step_fix_permissions

    print_section "BUILD TOOLS"
    run_step install_rust        11 "Rust toolchain"           step_install_rust
    _run_eww_step                   # Custom checkpoint: marks done only if binary appears

    print_section "SYSTEM INTEGRATION"
    run_step create_dirs          13 "Required directories"     step_create_dirs
    run_step systemd_reload       14 "systemd daemon-reload"    step_systemd_reload
    run_step systemd_enable_start 15 "Enable + start services"  step_systemd_enable_start
    run_step systemd_enable_only  16 "Enable Wayland services"  step_systemd_enable_only
    run_step create_pacman_hooks  17 "Pacman hooks"             step_create_pacman_hooks
    run_step set_default_shell    18 "Default shell → fish"     step_set_default_shell
    run_step mandb_user           19 "Man page index"           step_mandb_user
    run_step claude_skills        20 "Claude Code skills"       step_claude_skills

    _run_bluetooth               # Bonus step: not numbered, non-fatal

    step_select_theme            # Interactive: never checkpointed

    # Full success — remove checkpoint
    rm -f "$CHECKPOINT_FILE"

    show_post_install
}

main "$@"
