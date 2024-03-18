#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Exports
export EDITOR=$VISUAL
export TERM=xterm-256color
export VISUAL=vim
export LESS=-FRX
export CLICOLOR=1
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export PATH=~/.scripts:$PATH

# Aliases
# alias ls='ls --color=auto'
alias vi='vim'
alias grep='grep --color=auto'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Neovide
alias neo='~/.scripts/neo.sh'

# Screenshot using shotgun and hacksaw
# script in ~/.scripts already added to $PATH
alias shot='shot.sh'
# save art in clipboard to file
alias clip2file='xclip -selection clipboard -t image/png -o > "$(date +%Y-%m-%d_%T).png"'

## Exa
alias ls='exa --icons'
alias la='exa --icons -a'
alias lA='exa --icons -la'
alias ld='exa --icons -aD'
alias lD='exa --icons -laD'
alias lg='exa --icons -la --git'

# zoxide running in bash
eval "$(zoxide init bash)"
export _ZO_DATA_DIR=$HOME/.local/share
export _ZO_ECHO=1
export _ZO_EXCLUDE_DIRS="$HOME"
export _ZO_MAXAGE=1000
export _ZO_RESOLVE_SYMLINKS=1

# Prompt default
#PS1='[\u@\h \W]\$ ' 

#*********************
# starship prompt
#*********************
eval "$(starship init bash)"
#*********************

# Share command history between terminals
update_history() {
    history -a
    history -c
    history -r
}
shopt -s histappend
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTFILE=~/.bash_history
PROMPT_COMMAND="update_history; $PROMPT_COMMAND"
export PATH="$HOME/.cargo/bin:$PATH"
