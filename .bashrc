#
# ~/.bashrc - Versión mergeada y optimizada
#

# ===================================================================
# 1. Cargar configuraciones personales
# ===================================================================
# Cargar aliases y variables de entorno definidos en archivos externos
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

if [ -f ~/.env ]; then
    source ~/.env
fi

# ===================================================================
# 2. Salir si no se está en modo interactivo
# ===================================================================
[[ $- != *i* ]] && return

# ===================================================================
# 3. Aliases Básicos (como fallback)
# ===================================================================
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ===================================================================
# 4. Configuración del Título de la Ventana
# ===================================================================
case ${TERM} in
    xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
        ;;
    screen*)
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
        ;;
esac

# ===================================================================
# 5. Configuración de Colores y del Prompt
# ===================================================================
# Cargar configuración de colores si existe archivo de dircolors
if type -P dircolors >/dev/null ; then
    if [ -f ~/.dir_colors ]; then
        eval "$(dircolors -b ~/.dir_colors)"
    elif [ -f /etc/DIR_COLORS ]; then
        eval "$(dircolors -b /etc/DIR_COLORS)"
    fi
fi

# Configurar el prompt de forma diferenciada para root y usuarios normales
if [ "$EUID" -eq 0 ]; then
    PS1='\[\033[01;31m\][\h \W]\$\[\033[00m\] '
else
    PS1='\[\033[01;32m\][\u@\h \W]\$\[\033[00m\] '
fi

# Refrescar alias con colores (por si acaso)
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'

# ===================================================================
# 6. Funciones Utilitarias
# ===================================================================
# Función para mostrar ejemplos de secuencias de color
colors() {
    local fgc bgc vals seq
    echo "Ejemplos de secuencias de color:"
    for fgc in {30..37}; do
        for bgc in {40..47}; do
            vals="${fgc};${bgc}"
            seq="\e[${vals}m"
            printf " %sTEXT\e[0m" "${seq}"
        done
        echo
    done
}

# ===================================================================
# 7. Mejoras del Sistema y Ajustes Adicionales
# ===================================================================
# Permitir a root acceder a X (si es necesario)
xhost +local:root > /dev/null 2>&1

# Asegurarse de que el tamaño del terminal se actualice al cambiar de ventana
shopt -s checkwinsize
shopt -s expand_aliases

# Configurar que el historial se acumule en vez de sobrescribirse
shopt -s histappend

# Habilitar el modo vi en la línea de comandos
set -o vi

# --- Disable all pagers ------------------------
export PAGER=cat          # programa por defecto
export MANPAGER=cat       # man(1)
export SYSTEMD_PAGER=cat  # systemctl / journalctl
export GIT_PAGER=cat      # git log, diff, etc.

alias less='cat'
alias more='cat'

