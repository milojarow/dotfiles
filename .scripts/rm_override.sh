#!/bin/bash

function rm() {
        local interactive=0
    local force=0
    local recursive=0
    local targets=()

    for arg in "$@"; do
        if [ "$arg" = "-i" ]; then
            interactive=1
        elif [ "$arg" = "-f" ]; then
            force=1
        elif [ "$arg" = "-r" ] || [ "$arg" = "-R" ]; then
            recursive=1
        else
            targets+=("$arg")
        fi
    done

    for target in "${targets[@]}"; do
        if [ -e "$target" ] || [ $force -eq 1 ]; then
            if [ $interactive -eq 1 ]; then
                read -p "Move $target to ~/.trash.d/? " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    local base=$(basename "$target")
                    local dest="$HOME/.trash.d/$base"
                    local counter=1
                    while [ -e "$dest" ]; do
                        dest="$HOME/.trash.d/${base}_($counter)"
                        counter=$((counter + 1))
                    done
                    mv "$target" "$dest"
                    echo "Moved $target to $dest"
                fi
            else
                local base=$(basename "$target")
                local dest="$HOME/.trash.d/$base"
                local counter=1
                while [ -e "$dest" ]; do
                    dest="$HOME/.trash.d/${base}_($counter)"
                    counter=$((counter + 1))
                done
                mv "$target" "$dest"
                echo "Moved $target to $dest"
            fi
        else
            echo "$target does not exist."
        fi
    done
}
