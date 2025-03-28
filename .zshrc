# ~/.zshrc - Versión mergeada y optimizada

# ===================================================================
# 1. Cargar Configuración Default de Cachy OS (si existe)
# ===================================================================
if [ -f /usr/share/cachyos-zsh-config/cachyos-config.zsh ]; then
    source /usr/share/cachyos-zsh-config/cachyos-config.zsh
fi

# ===================================================================
# 2. Configuraciones de Apariencia y Prompt
# ===================================================================
export USE_POWERLINE="true"
export HAS_WIDECHARS="false"

# Cargar configuraciones y prompt de Manjaro si están disponibles
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
    source /usr/share/zsh/manjaro-zsh-config
fi

if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
    source /usr/share/zsh/manjaro-zsh-prompt
fi

# ===================================================================
# 3. Configuración Personal de milo
# ===================================================================
# Habilitar modo vi en Zsh
bindkey -v

# Cargar aliases y variables de entorno personales
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

if [ -f ~/.env ]; then
    source ~/.env
fi

# ===================================================================
# 4. Personalizaciones Adicionales
# ===================================================================
# Aquí puedes agregar más configuraciones o funciones propias

