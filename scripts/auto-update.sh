#!/bin/bash
# 月次で Brewfile とエージェントスキルを更新し、変更があれば commit & push する。
# launchd (com.masaki.auto-update) から毎日 2:00 に起動され、30日間隔で実処理する。
# 失敗時は macOS 通知 + ログ (~/.local/share/auto-update.log) で知らせる。

DOTFILES_DIR="$HOME/ghq/github.com/masaki39/dotfiles"
TIMESTAMP_FILE="$HOME/.local/share/auto-update-last-run"
LOG_FILE="$HOME/.local/share/auto-update.log"
INTERVAL_DAYS=30

BREW=/opt/homebrew/bin/brew
PNPM=/opt/homebrew/bin/pnpm
GIT=/opt/homebrew/bin/git

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"auto-update 失敗\" sound name \"Basso\"" 2>/dev/null || true
}

fail() {
    log "FAILED: $1"
    notify "$1"
    exit 1
}

# 30日インターバルガード
if [ -f "$TIMESTAMP_FILE" ]; then
    last_run=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    if [ "$(( (now - last_run) / 86400 ))" -lt "$INTERVAL_DAYS" ]; then
        exit 0
    fi
fi

log "Starting auto-update"
cd "$DOTFILES_DIR" || fail "cd $DOTFILES_DIR"

# 作業ツリーが汚れている場合はローカル変更を壊さないよう中断
if ! "$GIT" diff --quiet || ! "$GIT" diff --cached --quiet; then
    fail "working tree is dirty; commit or stash local changes first"
fi

# Brewfile 更新
"$BREW" bundle dump --force --file="$DOTFILES_DIR/Brewfile" >>"$LOG_FILE" 2>&1 || fail "brew bundle dump"
log "Brewfile dumped"

# エージェントスキル更新
"$PNPM" dlx skills update -g -y >>"$LOG_FILE" 2>&1 || fail "skills update"
log "skills update done"

# 変更をコミット & push
"$GIT" add Brewfile agents || fail "git add"
if "$GIT" diff --cached --quiet; then
    log "no changes to commit"
else
    "$GIT" commit -m "chore: auto-update Brewfile and skills" >>"$LOG_FILE" 2>&1 || fail "git commit"
    "$GIT" push >>"$LOG_FILE" 2>&1 || fail "git push"
    log "committed and pushed"
fi

date +%s > "$TIMESTAMP_FILE"
log "auto-update complete"
