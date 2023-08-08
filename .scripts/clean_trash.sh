#!/bin/bash

find ~/.local/share/Trash/files/ -type f -mtime +30 -exec \rm {} \;
find ~/.local/share/Trash/info/ -type f -mtime +30 -exec \rm {} \;
