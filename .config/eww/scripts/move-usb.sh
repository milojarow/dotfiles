#!/usr/bin/env bash
# move-usb.sh <axis> <delta>
# Moves the defwindow usb-widget by modifying only its geometry block.
# Uses Python to avoid false matches from other defwindow blocks in the file.

YUCK="$HOME/.config/eww/widgets/usb-widget.yuck"

python3 - "$YUCK" "$1" "$2" << 'PYEOF'
import re, sys

path, axis, delta = sys.argv[1], sys.argv[2], int(sys.argv[3])

with open(path) as f:
    content = f.read()

# Match only the defwindow usb-widget block (stops at next defwindow or end)
block_re = re.compile(r'(\(defwindow usb-widget\b.*?)(?=\(defwindow|\Z)', re.DOTALL)
m = block_re.search(content)
if not m:
    sys.exit(1)

old_block = m.group(1)
val = int(re.search(rf':{axis} "(\d+)px"', old_block).group(1))
new_val = val + delta
new_block = re.sub(rf'(:{axis} ")(\d+)(px")', rf'\g<1>{new_val}\3', old_block, count=1)

with open(path, 'w') as f:
    f.write(content[:m.start()] + new_block + content[m.end():])
PYEOF

~/.cargo/bin/eww reload
