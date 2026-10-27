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
ln -sfn "$DOTFILES/yazi" ~/.config/yazi
ln -sfn "$DOTFILES/ghostty" ~/.config/ghostty
ln -sfn "$DOTFILES/nvim" ~/.config/nvim
ln -sfn "$DOTFILES/hammerspoon" ~/.hammerspoon
ln -sfn "$DOTFILES/zsh" ~/.config/zsh
ln -sfn "$DOTFILES/lazygit" ~/.config/lazygit
ln -sfn "$DOTFILES/pnpm" ~/.config/pnpm
ln -sfn "$DOTFILES/uv" ~/.config/uv
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# statusline は別リポジトリ(ClaudeCodeStatusLine fork)で保守。mascot.sh も同階層に必要
[ -d "$STATUSLINE_REPO" ] || ghq get git@github.com:masaki39/ClaudeCodeStatusLine
ln -sf "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
ln -sf "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
ln -sfn "$DOTFILES/claude/skills" ~/.claude/skills
mkdir -p ~/.claude/hooks
for hook in "$DOTFILES"/claude/hooks/*.sh; do
  ln -sf "$hook" ~/.claude/hooks/
done
# karabiner.ts が ~/.config/karabiner/karabiner.json に直接書き込む (リンク不要)
(cd "$DOTFILES/karabiner" && pnpm install && pnpm build)

# starship prompt preset
starship preset jetpack -o ~/.config/starship.toml

# Install yazi plugins
bash "$DOTFILES/yazi/install.sh"

# LaunchAgent for monthly maintenance (cache cleanup + outdated notification)
chmod +x "$DOTFILES/scripts/monthly-maintenance.sh"
PLIST2="$HOME/Library/LaunchAgents/com.masaki.monthly-maintenance.plist"
cp "$DOTFILES/scripts/com.masaki.monthly-maintenance.plist" "$PLIST2"
launchctl unload "$PLIST2" 2>/dev/null
launchctl load "$PLIST2"

# LaunchAgent for monthly auto-update (Brewfile)
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
