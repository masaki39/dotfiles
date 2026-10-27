#!/bin/bash
# Monthly: refresh the Brewfile and commit & push it if it changed.
# Agent skills are not auto-updated because their contents are reviewed first (run `pnpm dlx skills update -g` manually).
# Launched daily at 2:00 by launchd (com.masaki.auto-update); does real work every 30 days.
# Failures are reported via a macOS notification and the log (~/.local/share/auto-update.log).
# Checks and commits are limited to the Brewfile (the working tree is always dirty
# because Claude Code writes back to claude/settings.json at runtime).

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP_FILE="$HOME/.local/share/auto-update-last-run"
LOG_FILE="$HOME/.local/share/auto-update.log"
INTERVAL_DAYS=30

BREW=/opt/homebrew/bin/brew
GIT=/opt/homebrew/bin/git

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

notify() {
    /usr/bin/osascript -e "display notification \"$1\" with title \"auto-update failed\" sound name \"Basso\"" 2>/dev/null || true
}

fail() {
    log "FAILED: $1"
    notify "$1"
    exit 1
}

# 30-day interval guard
if [ -f "$TIMESTAMP_FILE" ]; then
    last_run=$(cat "$TIMESTAMP_FILE")
    now=$(date +%s)
    if [ "$(( (now - last_run) / 86400 ))" -lt "$INTERVAL_DAYS" ]; then
        exit 0
    fi
fi

log "Starting auto-update"
cd "$DOTFILES_DIR" || fail "cd $DOTFILES_DIR"

# Safety valve: do nothing off main, during a merge/rebase, or with unpushed commits other than our own
branch=$("$GIT" branch --show-current)
[ "$branch" = main ] || fail "aborted: on branch $branch, not main"
gitdir=$("$GIT" rev-parse --git-dir)
if [ -e "$gitdir/MERGE_HEAD" ] || [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; then
    fail "aborted: merge/rebase in progress"
fi
"$GIT" fetch -q origin main >>"$LOG_FILE" 2>&1 || fail "git fetch"
others=$("$GIT" log --format=%s origin/main..HEAD | grep -vxF "chore: auto-update Brewfile" || true)
[ -z "$others" ] || fail "aborted: unpushed commits exist (push them manually)"

# Abort only if the target path has manual changes (local changes elsewhere are ignored)
if ! "$GIT" diff --quiet -- Brewfile || ! "$GIT" diff --cached --quiet -- Brewfile; then
    fail "Brewfile has uncommitted changes; commit or stash them"
fi

# Refresh the Brewfile
"$BREW" bundle dump --force --file="$DOTFILES_DIR/Brewfile" >>"$LOG_FILE" 2>&1 || fail "brew bundle dump"
log "Brewfile dumped"

# Do not auto-commit removed entries (a transient lookup failure must not get pushed as a removal)
removed=$("$GIT" diff -U0 -- Brewfile | grep -E '^-(tap|brew|cask|uv|npm|mas|vscode) ' || true)
if [ -n "$removed" ]; then
    log "removed entries detected:"
    log "$removed"
    "$GIT" checkout -- Brewfile
    fail "entries were removed from the Brewfile; auto-commit aborted (see log)"
fi

# Commit & push the change
"$GIT" add Brewfile || fail "git add"
if "$GIT" diff --cached --quiet -- Brewfile; then
    log "no changes to commit"
else
    # Path-limited commit: never sweeps in changes staged on other paths
    "$GIT" commit -m "chore: auto-update Brewfile" -- Brewfile >>"$LOG_FILE" 2>&1 || fail "git commit"
    log "committed"
fi

# Also push anything a previous run failed to push (unpushed commits were verified to be our own)
if [ -n "$("$GIT" rev-list origin/main..HEAD)" ]; then
    "$GIT" push origin HEAD:main >>"$LOG_FILE" 2>&1 || fail "git push"
    log "pushed"
fi

date +%s > "$TIMESTAMP_FILE"
log "auto-update complete"
