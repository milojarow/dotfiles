#!/usr/bin/env bash
# feature: tmux-sessions
# role:    action
## Forces the subscribe loop to skip its sleep and start a new iteration.
## Called by the refresh button in tmux-sessions widget.
PID=$(pgrep -f 'bash.*tmux-sessions-subscribe.sh$' | head -1)
[[ -n "$PID" ]] && pkill -P "$PID"
