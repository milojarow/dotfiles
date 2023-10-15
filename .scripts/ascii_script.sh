#!/bin/bash

# Initialize ASCII code variable
ascii_code=""

# Capture numeric input until Enter is pressed
while : ; do
  read -r -n 1 key

  if [ "$key" == "" ]; then  # Enter was pressed
    break
  elif [[ "$key" =~ [0-9] ]]; then  # Append the digit to the ASCII code
    ascii_code="${ascii_code}${key}"
  fi
done

# Convert the ASCII code to a character and type it out using xdotool
char=$(printf "\\$(printf '%o' "$ascii_code")")
xdotool type "$char"
