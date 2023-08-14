#!/bin/sh -e

# Function to display help message
display_help() {
  echo "Usage: shot.sh"
  echo "Take a screenshot of a selected area and copy it to the clipboard."
  echo
  echo "Dependencies:"
  echo "  hacksaw    - Tool for selecting a region of the screen."
  echo "  shotgun    - Tool for taking a screenshot of the selected area."
  echo "  xclip      - Tool for copying the screenshot to the clipboard."
  echo
  echo "Example:"
  echo "  ./shot.sh    # Select an area and take a screenshot"
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
    echo "No arguments expected. Use 'shot.sh --help' for more information."
    exit 1
fi

selection=$(hacksaw -f "-i %i -g %g")
shotgun $selection - | xclip -t 'image/png' -selection clipboard
