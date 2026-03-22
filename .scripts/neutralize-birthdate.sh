#!/usr/bin/env bash
# Part of: neutralize-birthdate — systemd userdb birthDate neutralization
# See: man neutralize-birthdate(1)
# Related files:
#   /etc/systemd/system/neutralize-birthdate.service  (oneshot service)
#   /etc/systemd/system/neutralize-birthdate.path      (inotify watcher)
#   /etc/pacman.d/hooks/neutralize-birthdate.hook       (pacman hook)
#
# neutralize-birthdate.sh — Nullify the birthDate field in systemd userdb
# drop-in records for all human users (UID >= 1000).
#
# systemd PR #40954 (merged 2026-03-18) adds a birthDate field to userdb
# JSON records, feeding age data to xdg-desktop-portal for application-level
# age gating (California AB 1043, Brazil Lei 15.211). This script creates
# /etc/userdb/<user>.user drop-in files with birthDate set to null,
# preemptively neutralizing the field.
#
# Triggered by:
#   - systemd .path unit watching /etc/userdb/ and /etc/passwd
#   - pacman hook on systemd package upgrades
#
# Idempotent: safe to run multiple times. Skips users whose drop-in
# already has birthDate set to null.

set -euo pipefail

readonly USERDB_DIR="/etc/userdb"
readonly TAG="neutralize-birthdate"

log() { logger -t "$TAG" "$*"; }

mkdir -p "$USERDB_DIR"

modified=0
skipped=0
created=0

while IFS=: read -r username _x uid _gid _gecos _home _shell; do
    # Only human users: UID 1000–65533
    if [[ $uid -ge 1000 && $uid -lt 65534 ]]; then
        userdb_file="${USERDB_DIR}/${username}.user"
        uid_link="${USERDB_DIR}/${uid}.user"

        if [[ -f "$userdb_file" ]]; then
            # Existing drop-in: check if birthDate is already null
            # Exit 42 = already neutralized (idempotency guard)
            # Exit 0  = file was modified
            # Exit 1  = error
            rc=0
            python3 -c '
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
if data.get("birthDate") is None:
    sys.exit(42)
data["birthDate"] = None
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
' "$userdb_file" || rc=$?

            if [[ $rc -eq 42 ]]; then
                skipped=$((skipped + 1))
            elif [[ $rc -ne 0 ]]; then
                log "ERROR: failed to process ${userdb_file}"
                continue
            else
                modified=$((modified + 1))
                log "${username}: birthDate neutralized (existing record)"
            fi
        else
            # New drop-in: minimal record — the Multiplexer merges with
            # NSS data from /etc/passwd, so only userName, uid, and
            # birthDate are needed
            printf '{\n  "userName": "%s",\n  "uid": %d,\n  "birthDate": null\n}\n' \
                "$username" "$uid" > "$userdb_file"
            chmod 0644 "$userdb_file"
            created=$((created + 1))
            log "${username}: birthDate neutralized (new record)"
        fi

        # UID symlink for UID-based lookups (userdbctl user <uid>)
        if [[ ! -L "$uid_link" ]] || [[ "$(readlink "$uid_link")" != "${username}.user" ]]; then
            ln -sf "${username}.user" "$uid_link"
        fi
    fi
done < /etc/passwd

# Restart userdbd so it picks up changes (CanReload=no, restart is the
# only option). Only if we actually wrote something.
if [[ $((modified + created)) -gt 0 ]]; then
    if systemctl is-active --quiet systemd-userdbd.service; then
        systemctl restart systemd-userdbd.service
        log "restarted systemd-userdbd.service"
    fi
fi

log "done: created=${created} modified=${modified} skipped=${skipped}"
