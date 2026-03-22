#!/bin/bash
# ── Drop Zone ────────────────────────────────────────────────────────────────
# Core sync script. Watches ~/shared/selene/ and pushes changes to selene VPS.
# Event-driven via inotifywait. Progress logged to /tmp/sync-selene.log.
# See: man drop-zone
# ─────────────────────────────────────────────────────────────────────────────

WATCH_DIR="$HOME/shared/selene"
REMOTE="endymion@selene:~/shared/"
LOG="/tmp/sync-selene.log"

mkdir -p "$WATCH_DIR"
: > "$LOG"

inotifywait -mr -e close_write,moved_to,delete "$WATCH_DIR" --format '%e %w%f' |
while read -r event file; do
  # Auto-spawn monitor window if not already open (don't disturb scratchpad)
  swaymsg -t get_tree 2>/dev/null | grep -q '"app_id":"sync-selene"' || \
    swaymsg exec "$HOME/.scripts/sync-selene-monitor.sh" 2>/dev/null
  name="${file#$WATCH_DIR/}"
  echo "$(date '+%H:%M:%S') ── syncing: $name" >> "$LOG"
  start=$(date +%s)
  /usr/sbin/rsync -ahz --delete --info=progress2 "$WATCH_DIR/" "$REMOTE" 2>&1 >> "$LOG"
  elapsed=$(( $(date +%s) - start ))
  echo "$(date '+%H:%M:%S') ── done (${elapsed}s)" >> "$LOG"
  echo "" >> "$LOG"
  notify-send -a "sync-selene" "Sync complete" "$name (${elapsed}s)"
done
