# ~/.zshrc — User-level Zsh configuration

# 1) Disable Powerlevel10k configuration wizard (keep fallback theme)
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Instant prompt (keep this block near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source CachyOS default Zsh + Oh My Zsh settings
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# To customize prompt settings, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 2) Enable vi-mode editing at the prompt
#    Placed **after** all sourcing so it takes effect
bindkey -v

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

