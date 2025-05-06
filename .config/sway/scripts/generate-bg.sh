#!/usr/bin/env sh
set -xu

export CROWN=$1
export ROOT=$2
export BACKGROUND=$3

# shellcheck disable=SC2002
cat ~/.config/sway/templates/manjarosway-scalable.svg | envsubst > "$HOME/.config/sway/generated_background.svg"
