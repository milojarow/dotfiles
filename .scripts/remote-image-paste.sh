#!/usr/bin/env bash
# Take the image from the local Wayland clipboard, scp it to a remote host,
# then type the resulting absolute path into the currently focused window
# via wtype. Intended use: paste an image into a remote claude code CLI
# running inside a tmux session, where ctrl+v cannot reach the local clipboard.
#
# Bound in sway to Super+Shift+V.

set -euo pipefail

REMOTE_HOST="selene"
REMOTE_DIR="/tmp"

mime=$(wl-paste --list-types 2>/dev/null | grep -m1 '^image/' || true)
if [[ -z "$mime" ]]; then
    notify-send -u low "Remote image paste" "No image in local clipboard"
    exit 0
fi

case "$mime" in
    image/png)  ext="png" ;;
    image/jpeg) ext="jpg" ;;
    image/gif)  ext="gif" ;;
    image/webp) ext="webp" ;;
    *)          ext="${mime#image/}" ;;
esac

local_tmp=$(mktemp --suffix=".$ext" /tmp/remote-image-paste.XXXXXX)
trap 'rm -f "$local_tmp"' EXIT

if ! wl-paste --type "$mime" > "$local_tmp"; then
    notify-send -u critical "Remote image paste" "Failed to read image from clipboard"
    exit 1
fi

remote_name="cc-paste-$(date +%Y%m%d-%H%M%S).$ext"
remote_path="$REMOTE_DIR/$remote_name"

if ! scp_err=$(scp -q "$local_tmp" "${REMOTE_HOST}:${remote_path}" 2>&1); then
    notify-send -u critical "Remote image paste" "scp failed: ${scp_err:-unknown error}"
    exit 1
fi

if ! wtype "$remote_path"; then
    notify-send -u normal "Remote image paste" "Uploaded to ${remote_path} but wtype failed; type the path manually"
    exit 1
fi
