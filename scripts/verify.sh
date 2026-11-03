#!/bin/bash
# Verify a set-up machine (used by CI and by AGENTS.md). It does not change any config or links,
# but the first nvim start may install plugins and zsh may write its own state files.
# Prints ok/FAIL per check and exits non-zero if any check failed.
# When adding a link to setup.sh, add it to the link checks below too.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUSLINE_REPO="$HOME/ghq/github.com/masaki39/ClaudeCodeStatusLine"
failures=0

ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*"; failures=$((failures + 1)); }

# $1 = link source, $2 = link path (same argument order as setup.sh's link).
# Resolved paths are compared, so equivalent links (e.g. the skills CLI's ~/.agents/skills/<name>) pass.
check_link() {
  if [ -L "$2" ] && [ -e "$2" ] && [ "$(realpath "$2")" = "$(realpath "$1")" ]; then
    ok "$2"
  else
    fail "$2 (expected a link to $1)"
  fi
}

echo "== links"
check_link "$DOTFILES/pnpm" ~/.config/pnpm
check_link "$DOTFILES/.gitconfig" ~/.gitconfig
check_link "$DOTFILES/.zshrc" ~/.zshrc
check_link "$DOTFILES/.zshenv" ~/.zshenv
check_link "$DOTFILES/.zprofile" ~/.zprofile
check_link "$DOTFILES/ssh/config" ~/.ssh/config
check_link "$DOTFILES/yazi" ~/.config/yazi
check_link "$DOTFILES/ghostty" ~/.config/ghostty
check_link "$DOTFILES/nvim" ~/.config/nvim
check_link "$DOTFILES/hammerspoon" ~/.hammerspoon
check_link "$DOTFILES/zsh" ~/.config/zsh
check_link "$DOTFILES/lazygit" ~/.config/lazygit
check_link "$DOTFILES/uv" ~/.config/uv
check_link "$DOTFILES/git" ~/.config/git
check_link "$DOTFILES/jinrai" ~/.config/jinrai
check_link "$DOTFILES/pplyz" ~/.config/pplyz
check_link "$DOTFILES/starship/starship.toml" ~/.config/starship.toml
check_link "$DOTFILES/agents" ~/.agents
check_link "$DOTFILES/claude/settings.json" ~/.claude/settings.json
check_link "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
check_link "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
check_link "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
for skill in "$DOTFILES"/claude/skills/*/ "$DOTFILES"/agents/skills/*/; do
  check_link "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done
for hook in "$DOTFILES"/claude/hooks/*.sh; do
  check_link "$hook" ~/.claude/hooks/"$(basename "$hook")"
done

echo "== karabiner"
if [ -s ~/.config/karabiner/karabiner.json ]; then ok "karabiner.json"; else fail "karabiner.json is missing or empty"; fi

echo "== yazi plugins"
# Every plugin pinned in yazi/package.toml must be installed (`use = "owner/repo[:name]"` -> <name>.yazi)
while read -r p; do
  name=${p##*[/:]}
  if [ -d ~/.config/yazi/plugins/"$name".yazi ]; then ok "yazi plugin $name"; else fail "yazi plugin $name"; fi
done < <(sed -n 's/^use = "\(.*\)"$/\1/p' "$DOTFILES/yazi/package.toml")

echo "== LaunchAgent plists"
# Checked from the repo templates as setup.sh renders them, so this also works in CI (agents not installed)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for f in "$DOTFILES"/scripts/*.plist; do
  out="$tmp/$(basename "$f")"
  sed "s|__DOTFILES__|$DOTFILES|g" "$f" > "$out"
  if ! plutil -lint -s "$out"; then
    fail "plist lint: $(basename "$f")"
  elif grep -q __DOTFILES__ "$out"; then
    fail "unsubstituted __DOTFILES__ in $(basename "$f")"
  else
    ok "plist $(basename "$f")"
  fi
done

echo "== zsh startup"
out=$(zsh -lic 'whence -p brew pnpm difit fzf starship yazi nvim zoxide claude uv pplyz && print SHELL_OK' 2>&1) || true
if printf '%s\n' "$out" | grep -E 'command not found|no such file|parse error'; then
  fail "zsh startup printed errors"
elif printf '%s\n' "$out" | grep -qx SHELL_OK; then
  ok "zsh startup (all commands found)"
else
  printf '%s\n' "$out"
  fail "zsh startup (SHELL_OK not printed)"
fi

echo "== nvim startup"
# A first start installs plugins (progress lines on stderr), so it is only checked for errors;
# the next start must print nothing at all
out=$(nvim --headless +qa 2>&1) || fail "nvim exited non-zero"
if printf '%s\n' "$out" | grep -Ei 'error|E[0-9]+:'; then
  fail "nvim startup printed errors"
else
  out=$(nvim --headless +qa 2>&1) || fail "nvim exited non-zero (second start)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; fail "nvim startup printed output"; else ok "nvim startup"; fi
fi

if [ "$failures" -gt 0 ]; then
  echo "verify: $failures check(s) FAILED"
  exit 1
fi
echo "verify: all checks passed"
