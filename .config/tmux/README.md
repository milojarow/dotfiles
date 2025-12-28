# tmux Quick Reference for Persistent SSH Sessions

## Why tmux?

When you suspend your computer during an SSH session:
- SSH connection freezes/disconnects
- tmux session keeps running on the server
- When you reconnect, everything is exactly as you left it
- Perfect for Claude Code CLI with pending questions

## Quick Start

### Connect with tmux (recommended)

```bash
# Using the ssht helper function (auto-creates/attaches to tmux)
ssht hostinger-vps work

# Or manually
ssh hostinger-vps
tmux new -s work        # Create session named "work"
```

### Reconnect after suspend

```bash
# Using helper
ssht hostinger-vps work

# Or manually
ssh hostinger-vps
tmux attach -t work     # Attach to session "work"
```

## Essential Commands

### Session Management

- `tmux new -s name` - Create new session with name
- `tmux ls` - List all active sessions
- `tmux attach -t name` - Attach to session by name
- `tmux kill-session -t name` - Kill session by name
- `Ctrl+b d` - Detach from session (leaves it running)

### Inside tmux

- `Ctrl+b ?` - Show all keybindings (press q to exit)
- `Ctrl+b c` - Create new window
- `Ctrl+b n` - Next window
- `Ctrl+b p` - Previous window
- `Ctrl+b ,` - Rename current window
- `Ctrl+b %` - Split window vertically
- `Ctrl+b "` - Split window horizontally
- `Ctrl+b arrow` - Navigate between panes

## Workflow Example

```bash
# Day 1: Start working
ssht hostinger-vps blindando
# ... working with Claude Code CLI
# ... Claude asks you questions
# Computer dies/suspend

# Day 2: Resume work
ssht hostinger-vps blindando
# You're back exactly where you left off!
# Claude's questions are still there, ready to answer
```

## Tips

- Use descriptive session names: `blindando`, `finanzas`, `personal`
- You can have multiple sessions running simultaneously
- Sessions survive SSH disconnects, system suspend, and even server reboots (if configured)
- tmux runs on the SERVER, not your local machine
