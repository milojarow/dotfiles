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

# Add npm global bin to PATH (must be before aliases that use npm binaries)
fish_add_path $HOME/.npm-global/bin

# aliases
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'
alias claude='claude --dangerously-skip-permissions'

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

# --- Disable all pagers ------------------------
set -Ux PAGER bat
set -Ux MANPAGER bat
set -Ux SYSTEMD_PAGER bat
set -Ux GIT_PAGER bat

# Default editor configuration
set -gx EDITOR vim
set -gx VISUAL vim

# Kubernetes config for Hostinger VPS
set -gx KUBECONFIG "$HOME/.kube/config-hostinger"

# Disable focus reporting mode (prevents [O[I characters when switching windows)
printf "\e[?1004l"

# Override fish_title to always include current directory
# This ensures waybar can extract the path even when commands are running
# Includes shell PID for footclient CWD detection (footclient shares PID across all terminals)
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

    # Include shell PID at the end for waybar to map window -> shell -> CWD
    # Format: "~/path [PID]" or "~/path: command - command [PID]"
    # Use full path instead of abbreviated prompt_pwd for waybar clarity
    echo (pwd | sed "s|^$HOME|~|")$command_part" [$fish_pid]"
end


