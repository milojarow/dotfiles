#!/usr/bin/env python3
"""
wifi-scan.py — eww defpoll source for the wifi manager widget.

Outputs a single JSON object with all networks (available + saved-only):
  {"networks": [
    {"ssid": "MyNet", "signal": 72, "security": "WPA2",
     "in_use": true, "known": true, "available": true, "icon": "󰤥"},
    {"ssid": "OldNet", "signal": 0, "security": "WPA2",
     "in_use": false, "known": true, "available": false, "icon": "󰤭"}
  ]}

Sort order: in_use first → available by signal desc → saved-only at bottom.
"""

import json
import subprocess

# Signal strength icons (same as wifi-subscribe.py)
ICONS = [
    "\U000f092f",  # 0 bars  (< 20%)
    "\U000f091f",  # 1 bar   (20–39%)
    "\U000f0922",  # 2 bars  (40–59%)
    "\U000f0925",  # 3 bars  (60–79%)
    "\U000f0928",  # 4 bars  (80–100%)
]
ICON_SAVED = "\U000f092b"   # saved/offline network icon


def signal_icon(pct):
    if pct >= 80: return ICONS[4]
    if pct >= 60: return ICONS[3]
    if pct >= 40: return ICONS[2]
    if pct >= 20: return ICONS[1]
    return ICONS[0]


def get_known_ssids():
    """Return set of SSIDs with a saved wifi connection."""
    r = subprocess.run(
        ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"],
        capture_output=True, text=True
    )
    known = set()
    for line in r.stdout.splitlines():
        parts = line.split(":")
        if len(parts) >= 2 and parts[1] == "802-11-wireless":
            known.add(parts[0])
    return known


def get_available_networks(known_ssids):
    """Parse nmcli wifi list output into a deduplicated dict keyed by SSID."""
    r = subprocess.run(
        ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"],
        capture_output=True, text=True
    )
    networks = {}
    for line in r.stdout.splitlines():
        # nmcli -t escapes colons in values as \: — split on unescaped colons
        parts = line.replace("\\:", "\x00").split(":")
        parts = [p.replace("\x00", ":") for p in parts]
        if len(parts) < 4:
            continue
        ssid, signal_str, security, in_use_str = parts[0], parts[1], parts[2], parts[3]
        if not ssid:
            continue
        signal = int(signal_str) if signal_str.isdigit() else 0
        security = security if security not in ("", "--") else ""
        in_use = in_use_str.strip() == "*"
        # Keep entry with strongest signal when SSID appears multiple times
        if ssid not in networks or signal > networks[ssid]["signal"]:
            networks[ssid] = {
                "ssid":      ssid,
                "signal":    signal,
                "security":  security,
                "in_use":    in_use,
                "known":     ssid in known_ssids,
                "available": True,
                "icon":      signal_icon(signal),
            }
    return networks


def main():
    try:
        known_ssids = get_known_ssids()
        networks = get_available_networks(known_ssids)

        # Add saved-only entries (known but not visible in scan)
        for ssid in known_ssids:
            if ssid not in networks:
                networks[ssid] = {
                    "ssid":      ssid,
                    "signal":    0,
                    "security":  "",
                    "in_use":    False,
                    "known":     True,
                    "available": False,
                    "icon":      ICON_SAVED,
                }

        result = sorted(
            networks.values(),
            key=lambda n: (not n["in_use"], not n["available"], -n["signal"])
        )
        print(json.dumps({"networks": result}, ensure_ascii=False), flush=True)

    except Exception as e:
        print(json.dumps({"networks": []}), flush=True)


if __name__ == "__main__":
    main()
