#!/bin/bash

set -e

DOTFILES="$HOME/ghq/github.com/masaki39/dotfiles"
STATUSLINE_REPO="$HOME/ghq/github.com/masaki39/ClaudeCodeStatusLine"

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homebrew/install/HEAD/install.sh)"
fi

# Install packages
brew bundle --file="$DOTFILES/Brewfile"

# Create directories
mkdir -p ~/.config ~/.ssh ~/.claude
chmod 700 ~/.ssh

# Symbolic links (force overwrite)
ln -sf "$DOTFILES/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.zshenv" ~/.zshenv
ln -sf "$DOTFILES/ssh/config" ~/.ssh/config
ln -sf "$DOTFILES/yazi" ~/.config/yazi
ln -sf "$DOTFILES/ghostty" ~/.config/ghostty
ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/hammerspoon" ~/.hammerspoon
ln -sf "$DOTFILES/zsh" ~/.config/zsh
ln -sf "$DOTFILES/lazygit" ~/.config/lazygit
ln -sf "$DOTFILES/pnpm" ~/.config/pnpm
ln -sf "$DOTFILES/uv" ~/.config/uv
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# statusline は別リポジトリ(ClaudeCodeStatusLine fork)で保守。mascot.sh も同階層に必要
[ -d "$STATUSLINE_REPO" ] || ghq get git@github.com:masaki39/ClaudeCodeStatusLine
ln -sf "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
ln -sf "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
ln -sf "$DOTFILES/claude/skills" ~/.claude/skills
mkdir -p ~/.config/karabiner
ln -sf "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json
if [ ! -s "$DOTFILES/karabiner/karabiner.json" ]; then
  echo '{"profiles":[{"name":"Default profile","complex_modifications":{"rules":[]}}]}' > "$DOTFILES/karabiner/karabiner.json"
fi
cd "$DOTFILES/karabiner" && pnpm build

# starship prompt preset
starship preset jetpack -o ~/.config/starship.toml

# Install yazi plugins
bash "$DOTFILES/yazi/install.sh"

# LaunchAgent for monthly maintenance
chmod +x "$DOTFILES/scripts/monthly-maintenance.sh"
PLIST2="$HOME/Library/LaunchAgents/com.masaki.monthly-maintenance.plist"
cp "$DOTFILES/scripts/com.masaki.monthly-maintenance.plist" "$PLIST2"
launchctl unload "$PLIST2" 2>/dev/null
launchctl load "$PLIST2"

# LaunchAgent for monthly auto-update (Brewfile + agent skills)
chmod +x "$DOTFILES/scripts/auto-update.sh"
# migrate old label
OLD_PLIST="$HOME/Library/LaunchAgents/com.masaki.update-brewfile.plist"
[ -f "$OLD_PLIST" ] && launchctl unload "$OLD_PLIST" 2>/dev/null && rm -f "$OLD_PLIST"
PLIST="$HOME/Library/LaunchAgents/com.masaki.auto-update.plist"
cp "$DOTFILES/scripts/com.masaki.auto-update.plist" "$PLIST"
launchctl unload "$PLIST" 2>/dev/null
launchctl load "$PLIST"

# Menu bar shortcuts
defaults write com.google.Chrome NSUserKeyEquivalents '{
    "他のタブをすべて閉じる" = "@~w";
}'

echo "✓ Setup complete!"
