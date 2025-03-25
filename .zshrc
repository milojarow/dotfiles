# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

# custom settings by milo
# vi mode
bindkey -v

# Cargar aliases comunes
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# Cargar variables de entorno comunes
if [ -f ~/.env ]; then
    source ~/.env
fi

