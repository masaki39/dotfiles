#!/bin/bash
# Monthly: refresh the Brewfile and commit & push it if it changed.
# Agent skills are not auto-updated because their contents are reviewed first (run `pnpm dlx skills update -g` manually).
# Launched daily at 3:00 by launchd (com.masaki.auto-update); does real work every 30 days.
# Staggered from monthly-maintenance (2:00) and serialized with it by a shared lockf lock, so brew never runs concurrently.
# Failures are reported via a macOS notification and the log (~/.local/share/auto-update.log).
# Checks and commits are limited to the Brewfile (the working tree is always dirty
# because Claude Code writes back to claude/settings.json at runtime).

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP_FILE="$HOME/.local/share/auto-update-last-run"
LOG_FILE="$HOME/.local/share/auto-update.log"
INTERVAL_DAYS=30
STALE_DAYS=45

BREW=/opt/homebrew/bin/brew
GIT=/opt/homebrew/bin/git

mkdir -p "$(dirname "$TIMESTAMP_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Serialize with the other brew job (auto-update / monthly-maintenance): both can start together
# (RunAtLoad at login or setup.sh reload, or missed calendar runs fired on wake), so run this
# script once more under a shared lock; the second job waits until the first one finishes.
# Not exec'd, so a lock timeout (lockf exits 75, e.g. the other job hangs) can be detected:
# it is only logged, and the next daily run retries.
if [ -z "${BREW_JOBS_LOCKED:-}" ]; then
    export BREW_JOBS_LOCKED=1
    lock_rc=0
    /usr/bin/lockf -k -t 3600 "$HOME/.local/share/brew-jobs.lock" /bin/bash "$0" "$@" || lock_rc=$?
    if [ "$lock_rc" -eq 75 ]; then
        log "skipped: timed out waiting for the brew job lock (another brew job is still running)"
        exit 0
    fi
    exit "$lock_rc"
fi

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

# Pushing needs the SSH key (a manual step after setup). While SSH does not work, skip quietly:
# no notification and no timestamp, so the next run tries again.
# ssh -T exits 1 even on success, so check both the exit code and the greeting.
ssh_out=$(/usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1)
ssh_rc=$?
# Once it has succeeded before (timestamp exists), a failure lasting past STALE_DAYS is notified.
if [ "$ssh_rc" -ne 1 ] || ! printf '%s\n' "$ssh_out" | grep -q "successfully authenticated"; then
    if [ -f "$TIMESTAMP_FILE" ]; then
        age_days=$(( ($(date +%s) - $(cat "$TIMESTAMP_FILE")) / 86400 ))
        if [ "$age_days" -gt "$STALE_DAYS" ]; then
            fail "GitHub SSH authentication failing (ssh exit $ssh_rc); Brewfile not refreshed for $age_days days"
        fi
    fi
    log "skipped: GitHub SSH authentication is not working (ssh exit $ssh_rc)"
    exit 0
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
