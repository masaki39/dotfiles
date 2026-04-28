#!/bin/bash

TIMESTAMP_FILE="$HOME/.local/share/monthly-maintenance-last-run"
INTERVAL_DAYS=30

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

if [ -f "$TIMESTAMP_FILE" ]; then
    last_run=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    diff=$(( (now - last_run) / 86400 ))
    if [ "$diff" -lt "$INTERVAL_DAYS" ]; then
        exit 0
    fi
fi

/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade
/opt/homebrew/bin/brew cleanup --prune=all
npm cache clean --force
/opt/homebrew/bin/uv cache clean
/opt/homebrew/bin/pnpm store prune

date +%s > "$TIMESTAMP_FILE"
