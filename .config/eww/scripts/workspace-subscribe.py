#!/usr/bin/env python3
"""
workspace-subscribe.py — eww deflisten source for the bar workspace widget.

Emits a JSON array on startup and on every sway workspace/window event.
Tracks the last-focused window per workspace to determine the displayed icon.
"""

import json
import subprocess
import sys

# ── Icon map ──────────────────────────────────────────────────────────────────
# Keys are lowercase app_id or window class (substring match as fallback).
ICON_MAP = {
    # Terminals
    "foot":                    "\ue285",
    "kitty":                   "\uea85",
    "alacritty":               "\uea85",
    "wezterm":                 "\uea85",
    "com.mitchellh.ghostty":   "\ue007",
    "ghostty":                 "\ue007",
    # Browsers
    "firefox":                 "\ue745",
    "librewolf":               "\ue745",
    "brave-browser":           "\ue639",
    "brave":                   "\ue639",
    # Messaging
    "altus":                   "\uf232",
    "org.telegram.desktop":    "\uf2c6",
    "telegramdesktop":         "\uf2c6",
    # File browsers
    "nemo":                    "\uf4d3",
    "nautilus":                "\uf4d3",
    "org.gnome.nautilus":      "\uf4d3",
    "thunar":                  "\uf4d3",
    "pcmanfm":                 "\uf4d3",
    # PDF viewers
    "org.pwmt.zathura":        "\U000f0226",
    "evince":                  "\U000f0226",
    "okular":                  "\U000f0226",
    # Text editors / IDEs
    "code":                    "\U000f1a7c",
    "vscodium":                "\U000f1a7c",
    "vscodium-url-handler":    "\U000f1a7c",
    "gedit":                   "\U000f1a7c",
    "kate":                    "\U000f1a7c",
    # Email
    "betterbird":              "\uf370",
    "thunderbird":             "\uf370",
    # Claude desktop
    "claude":                  "\U000f09d1",
    # Obsidian
    "obsidian":                "\ue2a6",
    # VLC
    "vlc":                     "\U000f057c",
    # s45-panel
    "s45-panel":               "\U000f0b5f",
}

ICON_UNKNOWN         = "\uebf2"
ICON_SCRATCHPAD_ONE  = "\U000f05af"
ICON_SCRATCHPAD_MANY = "\U000f05b2"

ALWAYS_SHOW = set(range(1, 10))  # workspaces 1-9 always visible


# ── Helpers ───────────────────────────────────────────────────────────────────

def swaymsg(args):
    r = subprocess.run(["swaymsg"] + args, capture_output=True, text=True)
    return json.loads(r.stdout)


def get_app_id(node):
    return (
        node.get("app_id")
        or (node.get("window_properties") or {}).get("class")
        or ""
    )


def icon_for(app_id):
    if not app_id:
        return ICON_UNKNOWN
    key = app_id.lower()
    if key in ICON_MAP:
        return ICON_MAP[key]
    for pattern, icon in ICON_MAP.items():
        if pattern in key or key in pattern:
            return icon
    return ICON_UNKNOWN


def walk_leaves(node, results):
    """Collect all leaf window nodes recursively."""
    children = node.get("nodes", []) + node.get("floating_nodes", [])
    if not children and node.get("type") not in ("root", "output", "workspace"):
        results.append(node)
    for child in children:
        walk_leaves(child, results)


def find_node(node, predicate):
    if predicate(node):
        return node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        r = find_node(child, predicate)
        if r:
            return r
    return None


def get_workspaces_in_tree(tree):
    """Return all workspace nodes from the tree."""
    results = []
    def walk(n):
        if n.get("type") == "workspace":
            results.append(n)
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            walk(c)
    walk(tree)
    return results


def get_scratchpad_windows(tree):
    scratch = find_node(tree, lambda n: n.get("name") == "__i3_scratch")
    if not scratch:
        return []
    return scratch.get("floating_nodes", [])


# ── State update ──────────────────────────────────────────────────────────────

def update_last_focused(last_focused, tree):
    """Walk tree and update last_focused[ws_num] for any focused leaf."""
    def walk(node, ws_num):
        if node.get("type") == "workspace":
            try:
                ws_num = int(node.get("num", -99))
            except (ValueError, TypeError):
                ws_num = -99
        if node.get("focused") and ws_num not in (-99, -1):
            app = get_app_id(node)
            if app:
                last_focused[ws_num] = app
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child, ws_num)
    walk(tree, -99)


# ── Output builder ────────────────────────────────────────────────────────────

def build_output(last_focused, tree, ws_raw):
    ws_by_num = {ws["num"]: ws for ws in ws_raw}

    result = []

    for num in range(1, 10):
        raw = ws_by_num.get(num, {"num": num, "name": str(num),
                                   "focused": False, "urgent": False})
        ws_name = raw.get("name", str(num))

        # Find workspace node in tree
        ws_node = find_node(tree,
            lambda n, name=ws_name: n.get("type") == "workspace" and n.get("name") == name
        )

        leaves = []
        if ws_node:
            walk_leaves(ws_node, leaves)
        has_windows = len(leaves) > 0

        if has_windows:
            icon_app = last_focused.get(num, "")
            if not icon_app and leaves:
                icon_app = get_app_id(leaves[0])
            icon = icon_for(icon_app)
        else:
            icon = str(num)

        result.append({
            "num":         num,
            "name":        ws_name,
            "focused":     raw.get("focused", False),
            "urgent":      raw.get("urgent", False),
            "has_windows": has_windows,
            "icon":        icon,
            "cmd":         "swaymsg workspace {}".format(num),
        })

    # Workspace 10 — only if it has content
    if 10 in ws_by_num:
        raw = ws_by_num[10]
        ws_name = raw.get("name", "10")
        ws_node = find_node(tree,
            lambda n, name=ws_name: n.get("type") == "workspace" and n.get("name") == name
        )
        leaves = []
        if ws_node:
            walk_leaves(ws_node, leaves)
        if leaves or raw.get("focused"):
            icon_app = last_focused.get(10, get_app_id(leaves[0]) if leaves else "")
            result.append({
                "num":         10,
                "name":        ws_name,
                "focused":     raw.get("focused", False),
                "urgent":      raw.get("urgent", False),
                "has_windows": len(leaves) > 0,
                "icon":        icon_for(icon_app) if leaves else "10",
                "cmd":         "swaymsg workspace 10",
            })

    # Scratchpad — only if it has content
    scratch_wins = get_scratchpad_windows(tree)
    if scratch_wins:
        count = len(scratch_wins)
        result.append({
            "num":         -1,
            "name":        "scratchpad",
            "focused":     False,
            "urgent":      False,
            "has_windows": True,
            "icon":        ICON_SCRATCHPAD_ONE if count == 1 else ICON_SCRATCHPAD_MANY,
            "cmd":         "swaymsg scratchpad show",
        })

    return result


def emit(data):
    print(json.dumps(data, ensure_ascii=False), flush=True)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    last_focused = {}

    tree   = swaymsg(["-t", "get_tree"])
    ws_raw = swaymsg(["-t", "get_workspaces"])
    update_last_focused(last_focused, tree)
    emit(build_output(last_focused, tree, ws_raw))

    # Subscribe to workspace + window events, pipe through jq for compact lines
    swaymsg_proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["workspace", "window"]'],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    jq_proc = subprocess.Popen(
        ["jq", "--unbuffered", "-c", "."],
        stdin=swaymsg_proc.stdout,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    swaymsg_proc.stdout.close()

    for line in jq_proc.stdout:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        change = event.get("change", "")

        # On window focus: update last_focused from event data directly
        if change == "focus":
            container = event.get("container", {})
            app = get_app_id(container)
            if app:
                # Find focused workspace from get_workspaces (cheap call)
                ws_raw = swaymsg(["-t", "get_workspaces"])
                for ws in ws_raw:
                    if ws.get("focused"):
                        last_focused[ws["num"]] = app
                        break
            tree = swaymsg(["-t", "get_tree"])
        else:
            tree   = swaymsg(["-t", "get_tree"])
            ws_raw = swaymsg(["-t", "get_workspaces"])
            update_last_focused(last_focused, tree)

        emit(build_output(last_focused, tree, ws_raw))


if __name__ == "__main__":
    main()
