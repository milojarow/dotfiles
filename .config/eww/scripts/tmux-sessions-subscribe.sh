#!/usr/bin/env bash
## Polls tmux sessions on selene every 60s and emits one line of JSON per
## iteration to stdout (eww deflisten pattern). On SSH failure, emits an
## "offline" payload so the widget can render a clear unreachable state.

set -u

trap 'printf "%s\n" "{\"sessions\":[],\"status\":\"stopped\",\"count\":0}"; exit 0' EXIT INT TERM

INTERVAL=60
SSH_OPTS=(-o ConnectTimeout=5 -o BatchMode=yes -o ServerAliveInterval=10 -o ServerAliveCountMax=2)
TMUX_FMT='#{session_name}|#{session_windows}|#{session_attached}|#{session_created}'

while true; do
    raw=$(ssh "${SSH_OPTS[@]}" selene "tmux ls -F '$TMUX_FMT' 2>/dev/null" 2>/dev/null)
    rc=$?

    if [[ $rc -ne 0 ]]; then
        printf '%s\n' '{"sessions":[],"status":"offline","count":0}'
    elif [[ -z "$raw" ]]; then
        printf '%s\n' '{"sessions":[],"status":"empty","count":0}'
    else
        json=$(printf '%s\n' "$raw" | jq -R -s -c --argjson now "$(date +%s)" '
            split("\n") | map(select(length > 0)) |
            map(split("|") | {
                name:     .[0],
                windows:  (.[1] | tonumber),
                attached: (.[2] == "1"),
                created:  (.[3] | tonumber),
                age_secs: ($now - (.[3] | tonumber))
            }) |
            { sessions: ., status: "ok", count: length }
        ')
        printf '%s\n' "$json"
    fi

    sleep "$INTERVAL"
done
