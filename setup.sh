#!/bin/bash

set -e

# DOTFILES_CI=1: for CI. Skips casks and LaunchAgent registration
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# An existing real file/directory is moved to <name>.bak.<timestamp> before linking
link() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    mv "$2" "$2.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $2"
  fi
  ln -sfn "$1" "$2"
}

# So pnpm and others read ~/.config (.zshenv is not in effect yet)
export XDG_CONFIG_HOME="$HOME/.config"
STATUSLINE_REPO="$HOME/ghq/github.com/masaki39/ClaudeCodeStatusLine"
STATUSLINE_URL="https://github.com/masaki39/ClaudeCodeStatusLine"

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homebrew/install/HEAD/install.sh)"
fi
# Right after installing, brew is not on this process's PATH yet
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages
# brew bundle installs uv tools with the latest Python (it does not pass env vars), which can
# break dependency builds, so they are filtered out here and installed later with a pinned Python
skip='^uv '
[ -n "${DOTFILES_CI:-}" ] && skip='^(uv|cask) '
BREWFILE=$(mktemp)
grep -Ev "$skip" "$DOTFILES/Brewfile" > "$BREWFILE"
brew bundle --file="$BREWFILE"
sed -n 's/^uv "\([^"]*\)".*/\1/p' "$DOTFILES/Brewfile" | while read -r tool; do
  uv tool install --python 3.13 "$tool"
done

# pnpm global packages (difit, etc.). .zprofile is not in effect yet, so set PATH here
mkdir -p ~/.config
# Apply minimumReleaseAge (pnpm/config.yaml) before the global install
link "$DOTFILES/pnpm" ~/.config/pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
xargs pnpm add -g < "$DOTFILES/pnpm/global-packages.txt"

# Claude Code (native build)
command -v claude >/dev/null || [ -x ~/.local/bin/claude ] || curl -fsSL https://claude.ai/install.sh | bash

# Create directories
mkdir -p ~/.config ~/.ssh ~/.claude
chmod 700 ~/.ssh

# Symbolic links (force overwrite)
link "$DOTFILES/.gitconfig" ~/.gitconfig
link "$DOTFILES/.zshrc" ~/.zshrc
link "$DOTFILES/.zshenv" ~/.zshenv
link "$DOTFILES/.zprofile" ~/.zprofile
link "$DOTFILES/ssh/config" ~/.ssh/config
link "$DOTFILES/yazi" ~/.config/yazi
link "$DOTFILES/ghostty" ~/.config/ghostty
link "$DOTFILES/nvim" ~/.config/nvim
link "$DOTFILES/hammerspoon" ~/.hammerspoon
link "$DOTFILES/zsh" ~/.config/zsh
link "$DOTFILES/lazygit" ~/.config/lazygit
link "$DOTFILES/uv" ~/.config/uv
link "$DOTFILES/git" ~/.config/git
link "$DOTFILES/jinrai" ~/.config/jinrai
link "$DOTFILES/pplyz" ~/.config/pplyz
# Install target of pnpm dlx skills -g
link "$DOTFILES/agents" ~/.agents
link "$DOTFILES/claude/settings.json" ~/.claude/settings.json
link "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# The statusline lives in a separate repo (ClaudeCodeStatusLine fork); mascot.sh must sit next to it
# Public repo, so clone over HTTPS (insteadOf in .gitconfig would turn it into SSH, which fails on a fresh machine without keys)
[ -d "$STATUSLINE_REPO" ] || GIT_CONFIG_GLOBAL=/dev/null git clone "$STATUSLINE_URL" "$STATUSLINE_REPO"
link "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
link "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
# ~/.claude/skills is a real directory (the skills CLI also links into it); link each skill individually
[ -L ~/.claude/skills ] && rm ~/.claude/skills  # migrate from the old layout (whole-directory link)
mkdir -p ~/.claude/skills
for skill in "$DOTFILES"/claude/skills/*/ "$DOTFILES"/agents/skills/*/; do
  link "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done
mkdir -p ~/.claude/hooks
for hook in "$DOTFILES"/claude/hooks/*.sh; do
  link "$hook" ~/.claude/hooks/"$(basename "$hook")"
done
# karabiner.ts writes ~/.config/karabiner/karabiner.json directly (no link needed)
# If Karabiner has never run the file is missing and the build fails, so seed a minimal one
mkdir -p ~/.config/karabiner
[ -s ~/.config/karabiner/karabiner.json ] ||
  echo '{"profiles":[{"name":"Default profile","selected":true,"complex_modifications":{"rules":[]}}]}' > ~/.config/karabiner/karabiner.json
(cd "$DOTFILES/karabiner" && pnpm install && pnpm build)

# starship prompt preset
starship preset jetpack -o ~/.config/starship.toml

# Install yazi plugins
bash "$DOTFILES/yazi/install.sh"

if [ -n "${DOTFILES_CI:-}" ]; then
  echo "✓ Setup complete! (CI: LaunchAgents skipped)"
  exit 0
fi

# LaunchAgent for monthly maintenance (cache cleanup + outdated notification)
chmod +x "$DOTFILES/scripts/monthly-maintenance.sh"
PLIST2="$HOME/Library/LaunchAgents/com.masaki.monthly-maintenance.plist"
sed "s|__DOTFILES__|$DOTFILES|g" "$DOTFILES/scripts/com.masaki.monthly-maintenance.plist" > "$PLIST2"
launchctl unload "$PLIST2" 2>/dev/null
launchctl load "$PLIST2"

# LaunchAgent for monthly auto-update (Brewfile)
chmod +x "$DOTFILES/scripts/auto-update.sh"
# migrate old label
OLD_PLIST="$HOME/Library/LaunchAgents/com.masaki.update-brewfile.plist"
[ -f "$OLD_PLIST" ] && launchctl unload "$OLD_PLIST" 2>/dev/null && rm -f "$OLD_PLIST"
PLIST="$HOME/Library/LaunchAgents/com.masaki.auto-update.plist"
sed "s|__DOTFILES__|$DOTFILES|g" "$DOTFILES/scripts/com.masaki.auto-update.plist" > "$PLIST"
launchctl unload "$PLIST" 2>/dev/null
launchctl load "$PLIST"

# Menu bar shortcuts (keys are menu item titles, so they must match the app's Japanese UI)
defaults write com.google.Chrome NSUserKeyEquivalents '{
    "他のタブをすべて閉じる" = "@~w";
}'

echo "✓ Setup complete!"
