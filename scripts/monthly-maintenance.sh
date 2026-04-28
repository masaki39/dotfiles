#!/bin/bash

set -e

TIMESTAMP_FILE="$HOME/.local/share/monthly-maintenance-last-run"
LOG_FILE="$HOME/.local/share/monthly-maintenance.log"
INTERVAL_DAYS=30

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

if [ -f "$TIMESTAMP_FILE" ]; then
    last_run=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    diff=$(( (now - last_run) / 86400 ))
    if [ "$diff" -lt "$INTERVAL_DAYS" ]; then
        exit 0
    fi
fi

log "Starting monthly maintenance"
/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade && log "brew upgrade done"
/opt/homebrew/bin/brew cleanup --prune=all && log "brew cleanup done"
npm cache clean --force && log "npm cache clean done"
/opt/homebrew/bin/uv cache clean && log "uv cache clean done"
/opt/homebrew/bin/pnpm store prune && log "pnpm store prune done"
log "Monthly maintenance complete"

date +%s > "$TIMESTAMP_FILE"
