function ranger
    # Use ueberzugpp sixel backend to prevent image previews from leaking
    # into other Sway workspaces (floating Wayland window bug)
    UB_OUTPUT=sixel command ranger $argv
    set rc $status
    # ueberzug daemonizes itself and ignores SIGTERM, leaving its floating
    # preview windows alive on screen after ranger exits. SIGKILL is required.
    pkill -9 -u (id -u) -x ueberzug 2>/dev/null
    pkill -9 -u (id -u) -x ueberzugpp 2>/dev/null
    return $rc
end
