source /usr/share/cachyos-fish-config/cachyos-config.fish

# Override "done" plugin settings (sourced by cachyos-config)
# Bell sound triggers foot urgency flag → workspace turns red in waybar
set -U __done_notify_sound 1
set -U __done_notification_urgency_level normal

# activar modo vi en línea de comandos
fish_vi_key_bindings

# fish 4.8.1 (#12122) rebound ctrl-right/left to forward/backward-token on every
# platform — one press swallows a whole argument, i.e. an entire autosuggested path.
# Restore the pre-4.8.1 Linux behavior: word-wise movement / partial accept.
bind -M insert ctrl-right forward-word
bind -M insert ctrl-left backward-word
bind ctrl-right forward-word
bind ctrl-left backward-word

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# PATH is set in ~/.config/environment.d/10-defaults.conf
# fish_add_path only needed for ~/.local/bin (pipx) since fish doesn't inherit it reliably
fish_add_path $HOME/.local/bin

# Load secrets from environment.d (systemd only injects these into user services,
# not into terminal sessions started via sway/TTY)
if test -f $HOME/.secrets/environment.d/11-secrets.conf
    while read -l line
        string match -qr '^\s*#' -- $line; and continue
        string match -qr '^\s*$' -- $line; and continue
        set -l parts (string split -m1 '=' -- $line)
        test (count $parts) -eq 2; or continue
        set -l value $parts[2]
        # Expand ${VAR} references (systemd environment.d syntax)
        for ref in (string match -arg '\$\{([A-Za-z_][A-Za-z0-9_]*)\}' -- $value)
            set -q $ref; or continue
            set value (string replace -a "\${$ref}" $$ref -- $value)
        end
        set -gx $parts[1] $value
    end <$HOME/.secrets/environment.d/11-secrets.conf
end

# aliases
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'

# Override CachyOS's default `update` (sudo pacman -Syu) with topgrade — one entrypoint
# for system + AUR (paru) + npm + cargo + zap AppImages. Defined after the cachyos-config
# source on line 1, so this always wins; cachyos-fish-config package updates can't undo it.
function update --wraps topgrade --description 'Update everything via topgrade'
    topgrade $argv
    set -l rc $status

    # mosh-osc52 self-heal: mosh linkea protobuf/abseil/utf8_range versionados; un bump de
    # soname lo deja con `ldd ... not found` y deja de arrancar (tu salvavidas remoto).
    # Detector directo (instantáneo, sin lock) + rebuild quirúrgico. Solo mosh — el resto lo
    # lista checkrebuild abajo. See memory reference_mosh_osc52_local_rebuild.
    if command -q mosh-server; and ldd (command -v mosh-server) 2>/dev/null | grep -q 'not found'
        set_color yellow; echo '⚠  mosh-osc52: soname roto tras el update — reconstruyendo...'; set_color normal
        pushd ~/.local/src/mosh-osc52 >/dev/null
        if makepkg -fC --noconfirm
            sudo pacman -U --noconfirm (makepkg --packagelist | string match -v '*-debug-*')
            if ldd (command -v mosh-server) 2>/dev/null | grep -q 'not found'
                set_color red; echo '   sigue roto tras el rebuild — revísalo a mano'; set_color normal
            else
                set_color green; echo '   reconstruido y reinstalado ✓'; set_color normal
            end
        else
            set_color red; echo '   el rebuild falló — arréglalo a mano en ~/.local/src/mosh-osc52'; set_color normal
        end
        popd >/dev/null
    end

    # Post-update: surface local/AUR packages left stale by a dependency's soname bump
    # (e.g. protobuf 34→35 breaking mosh-osc52). checkrebuild's pacman hook fires per
    # transaction but drowns in topgrade's output; this makes it the last thing on screen.
    # See memory reference_mosh_osc52_local_rebuild. No sudo, ~1-2 min for the foreign set.
    if type -q checkrebuild
        set_color brblack
        echo 'Buscando rebuilds pendientes (checkrebuild, ~1-2 min)...'
        set_color normal
        # </dev/null: without a tty, checkrebuild reads stdin as hook targets (mapfile)
        set -l stale (checkrebuild 2>/dev/null </dev/null | awk '{print $2}')
        if test -n "$stale"
            echo ''
            set_color yellow
            echo '⚠  Locales/AUR que piden rebuild (una lib cambió de soname bajo ellos):'
            set_color normal
            for pkg in $stale
                echo "     • $pkg"
            end
            set_color brblack
            echo '   Rebuild manual. Ej. mosh-osc52 → makepkg -fC en ~/.local/src/mosh-osc52/ + sudo pacman -U'
            set_color normal
        end
    end

    # Reboot pendiente: el hook de CachyOS solo avisa transitorio (echo en TTY + notif de
    # 10s, sin flag persistente); su rastro queda en pacman.log. Cubre los casos que el
    # test clásico de /usr/lib/modules/(uname -r) no ve (nvidia/mesa/systemd sin bump de kernel).
    set -l rb (grep -F 'Reboot is recommended' /var/log/pacman.log 2>/dev/null | tail -1 | string match -r '^\[(.*?)\]')
    if test (count $rb) -eq 2; and test (date -d $rb[2] +%s) -gt (date -d (uptime -s) +%s)
        set_color red
        echo '⚠  Reboot pendiente — paquete core (kernel/nvidia/mesa/systemd) actualizado después del último arranque'
        set_color normal
    end

    # Configs .pacnew/.pacsave pendientes (pacdiff lee la DB de pacman, sin sudo).
    # Ojo histórico: mkinitcpio.conf.pacnew se RECHAZA con rm (ver memoria mkinitcpio).
    if type -q pacdiff
        set -l pacnews (pacdiff --output 2>/dev/null)
        if test -n "$pacnews"
            set_color yellow
            echo '⚠  Configs .pacnew/.pacsave pendientes:'
            set_color normal
            for f in $pacnews
                echo "     • $f"
            end
        end
    end
    return $rc
end
# Wrapper: clear residual TUI lines Claude Code leaves after exiting
function claude
    command claude --dangerously-skip-permissions --effort max $argv
    # Erase any ghost lines the TUI left below the cursor
    printf '\e[J'
end

# Hermes with approval prompts disabled by default
function hermes
    command hermes --yolo $argv
end

function codex
    if test -x "$HOME/.codex/scripts/sync-agents-md.sh"
        "$HOME/.codex/scripts/sync-agents-md.sh"; or echo "warning: failed to sync Codex AGENTS.md" >&2
    end

    command codex --ask-for-approval never --sandbox danger-full-access $argv
end

# SSH with tmux for persistent sessions
function ssht
    set host $argv[1]
    set session_name $argv[2]

    if test -z "$session_name"
        set session_name "default"
    end

    ssh-tmux $host $session_name
end

# Function to check if a file exists in remote
function remote-exists
    set filepath $argv[1]
    if dots ls-tree -r --name-only origin/main | grep -q "^$filepath\$"
        echo "✅ File exists in remote"
    else
        echo "❌ File does not exist in remote"
    end
end

# Environment variables (EDITOR, PAGER, KUBECONFIG, etc.) are set in
# ~/.config/environment.d/10-defaults.conf — inherited by all processes

# Disable focus reporting mode (prevents [O[I characters when switching windows)
printf "\e[?1004l"

# Override fish_title to always include current directory
# This ensures waybar can extract the path even when commands are running
function fish_title
    set -l command_part ""
    set -l running_command (status current-command)

    # If there's a foreground command running, include it
    # $argv[1] contains the full command line with arguments (provided by Fish)
    # status current-command only returns the command name (no args)
    if test -n "$running_command" -a "$running_command" != "fish"
        set -l full_command $argv[1]
        if test -z "$full_command"
            set full_command $running_command
        end
        set command_part ": $full_command - $running_command"
    end

    # Include shell PID at the end; used by the footclient branch of window-title.sh
    # Format: "~/path [PID]" or "~/path: command - command [PID]"
    # Use full path instead of abbreviated prompt_pwd for waybar clarity
    echo (pwd | sed "s|^$HOME|~|")$command_part" [$fish_pid]"
end
