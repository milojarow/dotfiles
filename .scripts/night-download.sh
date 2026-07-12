#!/usr/bin/env bash
# night-download.sh — one-shot torrent download via aria2c, NO seeding, notify on done.
# Fired once by the systemd --user timer night-download.timer (2026-06-22 03:30).
# aria2c self-terminates on completion (--seed-time=0), so nothing to kill afterwards.
set -uo pipefail

MAGNETS=(
  'magnet:?xt=urn:btih:460e6e0e9f86e116f8d6757db8e078928aed9211&dn=Initial.D.Fifth.Stage.Cleo&tr=http://nyaa.tracker.wf:7777/announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://open.stealth.si:80/announce&tr=udp://exodus.desync.com:6969/announce'
  'magnet:?xt=urn:btih:c16e5399132fa696ee1776edc41fe7c3f9980594&dn=Initial.D.Final.Stage.Cleo&tr=http://nyaa.tracker.wf:7777/announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://open.stealth.si:80/announce&tr=udp://exodus.desync.com:6969/announce'
)

DEST="$HOME/torrents"   # carpeta del pipeline mal-tracking -> hardlinkea a ~/media/anime
LOG="$HOME/.cache/night-download.log"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

mkdir -p "$DEST" "$(dirname "$LOG")"
echo "=== INICIO $(date '+%F %T') ===" >> "$LOG"

# --seed-time=0  -> baja y sale, sin seedear (perfil mas bajo en el swarm)
# --bt-stop-timeout=3600 -> si tras 1h no hay progreso (torrent muerto), aborta
aria2c \
  --seed-time=0 \
  --bt-stop-timeout=3600 \
  --dir="$DEST" \
  --console-log-level=notice \
  --summary-interval=60 \
  "${MAGNETS[@]}" >> "$LOG" 2>&1
rc=$?

echo "=== FIN $(date '+%F %T') rc=$rc ===" >> "$LOG"

if [ "$rc" -eq 0 ]; then
  notify-send -u normal -t 0 "Descarga lista" "Initial D Fifth + Final Stage listos en ~/media/anime" 2>/dev/null || true
else
  notify-send -u critical -t 0 "Descarga FALLO" "aria2c rc=$rc - revisa $LOG" 2>/dev/null || true
fi
exit "$rc"
