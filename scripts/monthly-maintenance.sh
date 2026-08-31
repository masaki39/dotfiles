#!/bin/bash
# 月次のキャッシュ掃除。launchd (com.masaki.monthly-maintenance) から毎日 2:00 起動、30日間隔。
# 失敗時は macOS 通知 + ログ (~/.local/share/monthly-maintenance.log) で知らせる。

TIMESTAMP_FILE="$HOME/.local/share/monthly-maintenance-last-run"
LOG_FILE="$HOME/.local/share/monthly-maintenance.log"
INTERVAL_DAYS=30

BREW=/opt/homebrew/bin/brew
NPM=/opt/homebrew/bin/npm
PNPM=/opt/homebrew/bin/pnpm
UV=/opt/homebrew/bin/uv

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"monthly-maintenance 失敗\" sound name \"Basso\"" 2>/dev/null || true
}

if [ -f "$TIMESTAMP_FILE" ]; then
    last_run=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    if [ "$(( (now - last_run) / 86400 ))" -lt "$INTERVAL_DAYS" ]; then
        exit 0
    fi
fi

log "Starting monthly maintenance"

failed=0
step() {
    local name="$1"; shift
    if "$@" >>"$LOG_FILE" 2>&1; then
        log "$name done"
    else
        local rc=$?
        log "FAILED: $name (exit $rc)"
        notify "$name (exit $rc)"
        failed=1
    fi
}

step "brew update"      "$BREW" update
step "brew upgrade"     "$BREW" upgrade
step "brew cleanup"     "$BREW" cleanup --prune=all
step "npm cache clean"  "$NPM" cache clean --force
step "uv cache clean"   "$UV" cache clean
step "pnpm store prune" "$PNPM" store prune

if [ "$failed" -eq 0 ]; then
    log "Monthly maintenance complete"
else
    log "Monthly maintenance finished with errors"
fi

date +%s > "$TIMESTAMP_FILE"
