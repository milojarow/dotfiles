#!/usr/bin/env python3
"""
workspace-subscribe.py — eww deflisten source for the bar workspace widget.

Emits a JSON array on startup and on every sway workspace/window event.
Tracks the last-focused window per workspace to determine the displayed icon.
"""

import json
import os
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
    "org.telegram.desktop":    "\ue217",
    "telegramdesktop":         "\ue217",
    "discord":                 "\uf1ff",
    "vencord":                 "\uf1ff",
    # File browsers
    "nemo":                    "\uf114",
    "nautilus":                "\uf114",
    "org.gnome.nautilus":      "\uf114",
    "thunar":                  "\uf114",
    "pcmanfm":                 "\uf114",
    "ranger":                  "\uf114",
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
    "betterbird":              "\ueb1c",
    "thunderbird":             "\ueb1c",
    # Claude desktop
    "claude":                  "\U000f09d1",
    # Obsidian
    "obsidian":                "\ue2a6",
    # VLC
    "vlc":                     "\U000f057c",
    # pessoa
    "pessoa":        "\U000f0b5f",
    # Firefox with custom profile (app_id = profile name)
    "pessoa-blindando":        "\ue745",
    # MongoDB Compass
    "mongodb compass":         "\U000f032a",  # leaf (same as mongo-tunnel)
}

# TUI apps that run inside a terminal — identified by child process comm name.
# When a terminal leaf has a descendant process whose comm matches a key here,
# the mapped icon is shown instead of the terminal icon.
TERMINAL_TUI_APPS = {
    "ranger": "\uf114",  # file manager (same icon as nemo/nautilus)
}

_TERMINAL_APP_IDS = frozenset((
    "foot", "kitty", "alacritty", "wezterm",
    "com.mitchellh.ghostty", "ghostty",
))

ICON_UNKNOWN         = "\uebf2"
ICON_SCRATCHPAD_ONE  = "\U000f05af"
ICON_SCRATCHPAD_MANY = "\U000f05b2"
ICON_WS10            = "\U000F153C"  # secret workspace icon (U+F153C)

# Subscript number icons (Nerd Font U+F0B3A–U+F0B42) for workspace overlays.
# Workspace 10 and scratchpad (-1) fall back to plain string.
NUM_ICONS = {
    1: "\U000F0B3A",
    2: "\U000F0B3B",
    3: "\U000F0B3C",
    4: "\U000F0B3D",
    5: "\U000F0B3E",
    6: "\U000F0B3F",
    7: "\U000F0B40",
    8: "\U000F0B41",
    9: "\U000F0B42",
}

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


def _build_proc_children():
    """Return {ppid: [(pid, comm), ...]} for all running processes."""
    children = {}
    try:
        for entry in os.scandir("/proc"):
            if not entry.name.isdigit():
                continue
            pid = int(entry.name)
            try:
                ppid = 0
                with open(f"/proc/{pid}/status") as f:
                    for line in f:
                        if line.startswith("PPid:"):
                            ppid = int(line.split()[1])
                            break
                with open(f"/proc/{pid}/comm") as f:
                    comm = f.read().strip()
            except OSError:
                continue
            children.setdefault(ppid, []).append((pid, comm))
    except OSError:
        pass
    return children


def _find_descendant_tui(root_pid, children_map, max_depth=4):
    """BFS through process descendants; return TUI icon if a known app is found."""
    queue = [root_pid]
    visited = set()
    for _ in range(max_depth):
        next_queue = []
        for pid in queue:
            if pid in visited:
                continue
            visited.add(pid)
            for child_pid, comm in children_map.get(pid, []):
                if comm in TERMINAL_TUI_APPS:
                    return TERMINAL_TUI_APPS[comm]
                next_queue.append(child_pid)
        queue = next_queue
        if not queue:
            break
    return None


def icon_for_leaf(leaf, proc_children):
    """Resolve the icon for a sway leaf node, with TUI process override."""
    app_id = get_app_id(leaf)
    if app_id.lower() in _TERMINAL_APP_IDS:
        pid = leaf.get("pid")
        if pid:
            override = _find_descendant_tui(int(pid), proc_children)
            if override:
                return override
    return icon_for(app_id)


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


def compute_icon_lines(icons):
    """Return (top, mid, bot) row strings for the geometric icon display.

    Only 'top' is always non-empty.  'mid' and 'bot' are empty string ""
    when unused — callers should check has_mid / has_bot before rendering.

    Shapes (center-aligned labels give the geometric feel):
      1 → top=A                           single
      2 → top=AB                          pair
      3 → top=A,   mid=BC                 △  1+2
      4 → top=AB,  mid=CD                 □  2+2
      5 → top=AB,  mid=CDE               ⬠  2+3
      6 → top=ABC, mid=DEF               ⬡  3+3
      7 → top=ABC, mid=DEF, bot=G
      8 → top=ABC, mid=DEF, bot=GH
      9+→ top=ABC, mid=DEF, bot=GHI       (capped at 9 icons)
    """
    n = len(icons)
    j = "".join
    if n <= 2: return j(icons),       "",           ""
    if n == 3: return icons[0],       j(icons[1:]), ""
    if n == 4: return j(icons[:2]),   j(icons[2:]), ""
    if n == 5: return j(icons[:2]),   j(icons[2:]), ""
    if n == 6: return j(icons[:3]),   j(icons[3:]), ""
    return     j(icons[:3]),   j(icons[3:6]),j(icons[6:9])


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
    proc_children = _build_proc_children()

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
            icon_list = [icon_for_leaf(leaf, proc_children) for leaf in leaves]
            icon      = "".join(icon_list)
            top, mid, bot = compute_icon_lines(icon_list)
        else:
            icon      = str(num)
            top, mid, bot = str(num), "", ""

        result.append({
            "num":         num,
            "num_icon":    NUM_ICONS.get(num, str(num)),
            "name":        ws_name,
            "focused":     raw.get("focused", False),
            # Sway 1.11: workspace urgent flag sticks after urgent window moves away
            "urgent":      raw.get("urgent", False) and any(l.get("urgent", False) for l in leaves),
            "has_windows": has_windows,
            "icon":        icon,
            "icon_top":    top,
            "icon_mid":    mid,
            "icon_bot":    bot,
            "has_mid":     mid != "",
            "has_bot":     bot != "",
            "secret":      False,
            "cmd":         "swaymsg workspace {}".format(num),
        })

    # Workspace 10 — secret workspace: only visible when focused, fixed icon, no num, no app icons
    if 10 in ws_by_num and ws_by_num[10].get("focused"):
        raw10 = ws_by_num[10]
        result.append({
            "num":         10,
            "num_icon":    "",
            "name":        raw10.get("name", "10"),
            "focused":     True,
            "urgent":      raw10.get("urgent", False),
            "has_windows": False,
            "icon":        ICON_WS10,
            "icon_top":    ICON_WS10,
            "icon_mid":    "",
            "icon_bot":    "",
            "has_mid":     False,
            "has_bot":     False,
            "secret":      True,
            "cmd":         "swaymsg workspace 10",
        })

    # Scratchpad — only if it has content
    scratch_wins = get_scratchpad_windows(tree)
    if scratch_wins:
        count = len(scratch_wins)
        scratch_icon = ICON_SCRATCHPAD_ONE if count == 1 else ICON_SCRATCHPAD_MANY
        result.append({
            "num":         -1,
            "num_icon":    "-1",
            "name":        "scratchpad",
            "focused":     False,
            "urgent":      False,
            "has_windows": True,
            "icon":        scratch_icon,
            "icon_top":    scratch_icon,
            "icon_mid":    "",
            "icon_bot":    "",
            "has_mid":     False,
            "has_bot":     False,
            "secret":      False,
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
