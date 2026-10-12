#!/bin/bash
# 月次のキャッシュ掃除と更新チェック。launchd (com.masaki.monthly-maintenance) から毎日 2:00 起動、30日間隔。
# 失敗時は macOS 通知 + ログ (~/.local/share/monthly-maintenance.log) で知らせる。
# brew upgrade は自動実行しない (無人更新での破損や macOS の App Management ブロックを避けるため)。
# 更新があれば件数を通知するだけなので、手動で `brew upgrade` すること。

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

# brew update は git remote (SSH) の取得に失敗しても formula/cask の API データは更新されるため、
# 失敗はログに残すだけで通知しない
if "$BREW" update >>"$LOG_FILE" 2>&1; then
    log "brew update done"
else
    log "WARNING: brew update (exit $?)"
fi

outdated_formula=$("$BREW" outdated --formula --quiet 2>>"$LOG_FILE" | wc -l | tr -d ' ')
outdated_cask=$("$BREW" outdated --cask --quiet 2>>"$LOG_FILE" | wc -l | tr -d ' ')
log "outdated: formula $outdated_formula, cask $outdated_cask"
if [ "$outdated_formula" -gt 0 ] || [ "$outdated_cask" -gt 0 ]; then
    /usr/bin/osascript -e "display notification \"formula $outdated_formula / cask $outdated_cask 件。手動で brew upgrade してください\" with title \"Homebrew 更新あり\"" 2>/dev/null || true
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
