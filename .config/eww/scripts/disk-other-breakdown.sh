#!/bin/bash
# Find top 6 heaviest directories in $HOME excluding standard ones
# Output: JSON array sorted by size descending

HOME_DIR="$HOME"

du -d1 -k "$HOME_DIR" 2>/dev/null | \
  sort -rnk1 | \
  awk -v home="$HOME_DIR" '
    BEGIN { count = 0 }
    {
      dir = $2
      if (dir == home) next
      name = dir
      sub(home "/", "", name)
      if (name == "Documents" || name == "Pictures" || name == "Downloads" || name == "Videos") next
      sizes[count] = $1
      names[count] = name
      paths[count] = dir
      count++
    }
    END {
      n = (count < 6) ? count : 6
      printf "["
      for (i = 0; i < n; i++) {
        if (i > 0) printf ","
        size_mb = sizes[i] / 1024
        if (size_mb >= 1024) {
          size_str = sprintf("%.1fG", size_mb / 1024)
        } else {
          size_str = sprintf("%.0fM", size_mb)
        }
        printf "{\"name\":\"%s\",\"path\":\"%s\",\"size\":\"%s\"}", names[i], paths[i], size_str
      }
      printf "]\n"
    }'
