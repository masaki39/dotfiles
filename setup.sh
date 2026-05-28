#!/bin/bash

set -e

DOTFILES="$HOME/ghq/github.com/masaki39/dotfiles"

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
ln -sf "$DOTFILES/claude" ~/.claude
ln -sf "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

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

# LaunchAgent for auto Brewfile update
chmod +x "$DOTFILES/scripts/update-brewfile.sh"
PLIST="$HOME/Library/LaunchAgents/com.masaki.update-brewfile.plist"
cp "$DOTFILES/scripts/com.masaki.update-brewfile.plist" "$PLIST"
launchctl unload "$PLIST" 2>/dev/null
launchctl load "$PLIST"

# Menu bar shortcuts
defaults write com.google.Chrome NSUserKeyEquivalents '{
    "他のタブをすべて閉じる" = "@~w";
    "前のタブを選択" = "@~h";
    "次のタブを選択" = "@~l";
}'

echo "✓ Setup complete!"
