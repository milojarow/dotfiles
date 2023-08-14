#!/bin/bash

# Function to display help message
display_help() {
  echo "Usage: clean_trash.sh"
  echo "Clean the trash directory by removing files and related information that are older than 30 days."
  echo
  echo "This script targets the following directories:"
  echo "  ~/.local/share/Trash/files/"
  echo "  ~/.local/share/Trash/info/"
  echo
  echo "It finds files in these directories that have a modification time (mtime) older than 30 days and removes them."
  echo
  echo "Example:"
  echo "  ./clean_trash.sh    # Cleans trash files older than 30 days"
  echo
  echo "Note: This script does not accept any options or arguments and should be run without any."
}

# Check for the --help option
if [ "$1" == "--help" ]; then
  display_help
  exit 0
fi

# Check if any unwanted arguments are provided
if [ "$#" -ne 0 ]; then
    echo "No arguments expected. Use 'clean_trash.sh --help' for more information."
    exit 1
fi

# Find and remove files in the Trash that are older than 30 days
find ~/.local/share/Trash/files/ -type f -mtime +30 -exec \rm {} \;
find ~/.local/share/Trash/info/ -type f -mtime +30 -exec \rm {} \;
