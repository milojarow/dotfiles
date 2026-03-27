source /usr/share/cachyos-fish-config/cachyos-config.fish

# Override "done" plugin settings (sourced by cachyos-config)
# Bell sound triggers foot urgency flag → workspace turns red in waybar
set -U __done_notify_sound 1
set -U __done_notification_urgency_level normal

# activar modo vi en línea de comandos
fish_vi_key_bindings

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
        test (count $parts) -eq 2; and set -gx $parts[1] $parts[2]
    end <$HOME/.secrets/environment.d/11-secrets.conf
end

# aliases
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
# Wrapper: clear residual TUI lines Claude Code leaves after exiting
function claude
    command claude --dangerously-skip-permissions $argv
    # Erase any ghost lines the TUI left below the cursor
    printf '\e[J'
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


