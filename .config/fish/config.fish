source /usr/share/cachyos-fish-config/cachyos-config.fish

# activar modo vi en línea de comandos
fish_vi_key_bindings

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

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

# Add npm global bin to PATH
fish_add_path $HOME/.npm-global/bin

# Default editor configuration
set -gx EDITOR vim
set -gx VISUAL vim

# Kubernetes config for Hostinger VPS
set -gx KUBECONFIG "$HOME/.kube/config-hostinger"

# Disable focus reporting mode (prevents [O[I characters when switching windows)
printf "\e[?1004l"


