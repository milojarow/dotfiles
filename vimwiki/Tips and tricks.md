## Vim

#### Saves file when you forgot to open it as SUDO
`:w !sudo tee %`

#### Pulls help tags from plugins
`:helptags ~/.vim/doc`

## Dot Files

Este usuario hizo una investigación de qué es lo que casi todos tienen en sus dotfiles
https://github.com/Kharacternyk/dotcommon#window-managers

### Fonts

Algunas fuentes que tieneen los grandes:
`ttf-hack ttf-hack-nerd ttf-joypixels`

##  bashrc vim mode

comando para ver todos los bindings activos en ese momento bash modo vim
`bind -p | grep -v '^#\|self-insert\|^$'`

## Git 

#### git backtracking
`git checkout HEAD filename`: Discards changes in the working directory.
`git reset HEAD filename`: Unstages file changes in the staging area.
`git reset commit_SHA`: Resets to a previous commit in your commit history.

#### git submodules
Inside $HOME create the dir you want to use as a new repo.
Inside that dir run:
`git submodule init`
`git submodule set-url git@github.com:user/repo.git`
Check with `git remote -v` that in fact you linked your repo as remote of this submodule.
Ready, now you can start `adding`, `commiting` and `pushing`.


## bash scripting
### Comparison operators

Equal: `-eq`

Not equal: `-ne`

Less than or equal: `-le`

Less than: `-lt`

Greater than or equal: `-ge`

Greater than: `-gt`

Is null: `-z`



















