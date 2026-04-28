#!/bin/bash

DOTFILES_DIR="$HOME/ghq/github.com/masaki39/dotfiles"
TIMESTAMP_FILE="$HOME/.local/share/update-brewfile-last-run"
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

/opt/homebrew/bin/brew bundle dump --force --file="$DOTFILES_DIR/Brewfile"

cd "$DOTFILES_DIR" || exit 1
git add Brewfile
git diff --cached --quiet && exit 0
git commit -m "chore: update Brewfile (auto)"
git push

date +%s > "$TIMESTAMP_FILE"
