function ranger
    # Use ueberzugpp sixel backend to prevent image previews from leaking
    # into other Sway workspaces (floating Wayland window bug)
    UB_OUTPUT=sixel command ranger $argv
end
