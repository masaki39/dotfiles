#!/bin/bash

# Homebrew
brew bundle

# Create directories
mkdir -p ~/.config

# Symbolic links (force overwrite)
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/ssh/config ~/.ssh/config
ln -sf ~/dotfiles/yazi ~/.config/yazi
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/zellij ~/.config/zellij
ln -sf ~/dotfiles/nvim ~/.config/nvim

# Install yazi plugins
bash ~/dotfiles/yazi/install.sh

echo "✓ Setup complete!"
