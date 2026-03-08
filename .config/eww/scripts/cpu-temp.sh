#!/bin/bash
sensors -j | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(int(d['coretemp-isa-0000']['Package id 0']['temp1_input']))
"
