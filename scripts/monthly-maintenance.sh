#!/bin/bash
# Monthly cache cleanup and update check. Launched daily at 2:00 by launchd (com.masaki.monthly-maintenance); runs every 30 days.
# Failures are reported via a macOS notification and the log (~/.local/share/monthly-maintenance.log).
# Does not run brew upgrade automatically (avoids breakage from unattended upgrades and macOS App Management blocks).
# It only notifies the number of outdated packages; run `brew upgrade` manually.

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
    /usr/bin/osascript -e "display notification \"$1\" with title \"monthly-maintenance failed\" sound name \"Basso\"" 2>/dev/null || true
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

# brew update still refreshes formula/cask API data even if fetching a git remote (SSH) fails,
# so failures are only logged, not notified
if "$BREW" update >>"$LOG_FILE" 2>&1; then
    log "brew update done"
else
    log "WARNING: brew update (exit $?)"
fi

outdated_formula=$("$BREW" outdated --formula --quiet 2>>"$LOG_FILE" | wc -l | tr -d ' ')
outdated_cask=$("$BREW" outdated --cask --quiet 2>>"$LOG_FILE" | wc -l | tr -d ' ')
log "outdated: formula $outdated_formula, cask $outdated_cask"
if [ "$outdated_formula" -gt 0 ] || [ "$outdated_cask" -gt 0 ]; then
    /usr/bin/osascript -e "display notification \"$outdated_formula formulae / $outdated_cask casks outdated. Run brew upgrade manually.\" with title \"Homebrew updates available\"" 2>/dev/null || true
fi

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
