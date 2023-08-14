#!/bin/bash

# Function to display help message
display_help() {
  echo "Usage: rm_override.sh [OPTION] TARGET..."
  echo "Override the 'rm' command to move files or directories to ~/.trash.d/ instead of deleting them."
  echo
  echo "Options:"
  echo "  -i        Prompt before moving each target."
  echo "  -f        Force moving even if the target does not exist."
  echo "  -r, -R    Move directories recursively."
  echo "  --help    Display this help message and exit."
  echo
  echo "Arguments:"
  echo "  TARGET    One or more file or directory paths to be moved to ~/.trash.d/."
  echo
  echo "Example:"
  echo "  rm_override.sh -i file.txt    # Prompt before moving file.txt to ~/.trash.d/"
}

# Check for the --help option
if [ "$1" == "--help" ]; then
  display_help
  exit 0
fi

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

rm "$@"
