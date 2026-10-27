#!/bin/bash
# 月次で Brewfile を更新し、変更があれば commit & push する。
# エージェントスキルは中身を確認してから取り込むため自動更新しない (手動で `pnpm dlx skills update -g`)。
# launchd (com.masaki.auto-update) から毎日 2:00 に起動され、30日間隔で実処理する。
# 失敗時は macOS 通知 + ログ (~/.local/share/auto-update.log) で知らせる。
# 変更の検査・コミットは Brewfile に限定する (claude/settings.json は
# Claude Code が実行時に書き戻すため作業ツリーは常に汚れている)。

DOTFILES_DIR="$HOME/ghq/github.com/masaki39/dotfiles"
TIMESTAMP_FILE="$HOME/.local/share/auto-update-last-run"
LOG_FILE="$HOME/.local/share/auto-update.log"
INTERVAL_DAYS=30

BREW=/opt/homebrew/bin/brew
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

# 対象パスに手作業の変更が残っている場合のみ中断 (他パスのローカル変更は無視)
if ! "$GIT" diff --quiet -- Brewfile || ! "$GIT" diff --cached --quiet -- Brewfile; then
    fail "Brewfile に未コミットの変更あり; commit or stash してください"
fi

# Brewfile 更新
"$BREW" bundle dump --force --file="$DOTFILES_DIR/Brewfile" >>"$LOG_FILE" 2>&1 || fail "brew bundle dump"
log "Brewfile dumped"

# エントリの削除が出たら自動コミットしない (一時的な取得失敗で消えたまま push されるのを防ぐ)
removed=$("$GIT" diff -U0 -- Brewfile | grep -E '^-(tap|brew|cask|uv|npm|mas|vscode) ' || true)
if [ -n "$removed" ]; then
    log "removed entries detected:"
    log "$removed"
    "$GIT" checkout -- Brewfile
    fail "Brewfile から削除が出たので自動コミットを中止 (ログ参照)"
fi

# 変更をコミット & push
"$GIT" add Brewfile || fail "git add"
if "$GIT" diff --cached --quiet -- Brewfile; then
    log "no changes to commit"
else
    # パス指定コミット: 他パスにステージ済みの変更があっても巻き込まない
    "$GIT" commit -m "chore: auto-update Brewfile" -- Brewfile >>"$LOG_FILE" 2>&1 || fail "git commit"
    "$GIT" push >>"$LOG_FILE" 2>&1 || fail "git push"
    log "committed and pushed"
fi

date +%s > "$TIMESTAMP_FILE"
log "auto-update complete"
