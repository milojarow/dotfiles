#!/usr/bin/env bash
# move-icon.sh <scss-file> <property> <delta>
# Adjusts margin-left or margin-top in a scss file and reloads eww.

SCSS="$1"
PROPERTY="$2"
DELTA="$3"

python3 - "$SCSS" "$PROPERTY" "$DELTA" << 'PYEOF'
import re, sys, subprocess

scss_file, prop, delta = sys.argv[1], sys.argv[2], int(sys.argv[3])

with open(scss_file) as f:
    content = f.read()

pattern = rf'({re.escape(prop)}:\s*)(-?\d+)(px;)'
m = re.search(pattern, content)
if not m:
    print(f"Error: {prop} not found in {scss_file}", file=sys.stderr)
    sys.exit(1)

new_val = int(m.group(2)) + delta
new_content = re.sub(pattern, rf'\g<1>{new_val}\3', content, count=1)

with open(scss_file, 'w') as f:
    f.write(new_content)

subprocess.run(["/home/milo/.cargo/bin/eww", "reload"])
PYEOF
