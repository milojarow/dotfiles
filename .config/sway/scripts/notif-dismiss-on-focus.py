#!/usr/bin/env python3
# ── Notification Dismiss-on-Focus ─────────────────────────────────────────────
# Role:     Sway IPC event daemon. When a terminal window regains keyboard
#           focus, dismiss its lingering desktop notifications. Covers the case
#           where you reach the window WITHOUT clicking the notification
#           (Super+n, swayr, bar click) — clicking the notification itself
#           already focuses + closes it via foot's native window activation
#           (see ~/.config/foot/foot.ini [desktop-notifications], helper: fyi).
# Files:    notif-dismiss-on-focus.py
# Programs: swaymsg, makoctl
# Daemon:   ~/.config/systemd/user/notif-dismiss-on-focus.service
# Storage:  /tmp/notif-dismiss-on-focus-$USER.pid (single-instance guard)
# Scope:    Only app_ids in TARGET_APP_IDS. Kept to "foot" so the nchat / Altus
#           mako flows (click-to-open, badges) are left untouched. Matching is
#           app-id level: focusing any foot clears all foot notifications, since
#           BEL notifications carry no per-window identity.
# ─────────────────────────────────────────────────────────────────────────────

import json
import os
import subprocess
import sys

TARGET_APP_IDS = {"foot"}

PIDFILE = f"/tmp/notif-dismiss-on-focus-{os.environ.get('USER', 'user')}.pid"


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def dismiss_for(app_id):
    """Dismiss (no history) every mako notification whose app-name == app_id."""
    try:
        result = subprocess.run(
            ["makoctl", "list", "-j"], capture_output=True, text=True, check=False
        )
        if result.returncode != 0:
            return
        notifs = json.loads(result.stdout or "[]")
    except (json.JSONDecodeError, OSError) as exc:
        log(f"makoctl list failed: {exc}")
        return
    for n in notifs:
        if n.get("app_name") == app_id:
            subprocess.run(
                ["makoctl", "dismiss", "-n", str(n.get("id")), "-h"],
                capture_output=True, text=True, check=False,
            )


def single_instance():
    if os.path.exists(PIDFILE):
        try:
            old = int(open(PIDFILE).read().strip())
            os.kill(old, 15)  # SIGTERM
        except (ValueError, ProcessLookupError, PermissionError):
            pass
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))


def main():
    single_instance()
    log("notif-dismiss-on-focus subscribed to sway IPC")
    proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["window"]'],
        stdout=subprocess.PIPE, text=True, bufsize=1,
    )
    for line in proc.stdout:
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("change") != "focus":
            continue
        con = event.get("container") or {}
        app_id = con.get("app_id") or ""
        if app_id in TARGET_APP_IDS:
            dismiss_for(app_id)


if __name__ == "__main__":
    main()
