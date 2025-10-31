# ~/.zshrc — User-level Zsh configuration

# 1) Disable Powerlevel10k configuration wizard (keep fallback theme)
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Instant prompt (keep this block near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source CachyOS default Zsh + Oh My Zsh settings
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# Colorize comments in commands
ZSH_HIGHLIGHT_STYLES[comment]='fg=red'           # Comments in red (like Fish)
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'     # Invalid commands in red
ZSH_HIGHLIGHT_STYLES[command]='fg=white'         # Valid commands in white
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'           # Aliases in white
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'         # Builtins in white

# To customize prompt settings, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 2) Enable vi-mode editing at the prompt
#    Placed **after** all sourcing so it takes effect
bindkey -v
# Cursor shape for vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[2 q'  # steady block for command mode
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[6 q'  # steady bar for insert mode
  fi
}
zle -N zle-keymap-select

# Start with bar cursor
echo -ne '\e[6 q'

# Reset to bar when line finishes
function zle-line-init {
  echo -ne '\e[6 q'
}
zle -N zle-line-init

# 3) Source .aliases and .env only if they exist
if [[ -f "$HOME/.aliases" ]]; then
  source "$HOME/.aliases"
fi

if [[ -f "$HOME/.env" ]]; then
  source "$HOME/.env"
fi

# --- Disable all pagers ------------------------
export PAGER=bat
export MANPAGER=bat
export SYSTEMD_PAGER=bat
export GIT_PAGER=bat


# user custom behavior – disable command autocorrect
unsetopt correct           # desactiva CORRECT
unsetopt correct_all       # desactiva CORRECT_ALL


# Vi-mode history prefix search (like fish)
# Search history based on what you've typed so far
bindkey -M vicmd 'k' history-beginning-search-backward
bindkey -M vicmd 'j' history-beginning-search-forward

# Add npm global bin to PATH
export PATH="$HOME/.npm-global/bin:$PATH"
