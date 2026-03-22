#!/bin/bash
# ── Drop Zone ────────────────────────────────────────────────────────────────
# Monitor window toggle. Spawns a floating foot terminal with live sync log.
# See: man drop-zone
# ─────────────────────────────────────────────────────────────────────────────

if swaymsg '[app_id="sync-selene"] focus' 2>/dev/null; then
  exit 0
fi

foot --app-id sync-selene --title "sync → selene" -e bash -c 'tail -f /tmp/sync-selene.log 2>/dev/null; read'
