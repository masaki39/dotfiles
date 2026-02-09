# dotfiles

My personal settings.

## Setup

```zsh
bash setup.sh
```

This will:
- Install Homebrew packages
- Create symbolic links
- Install yazi plugins

## Manual setup (if needed)

### Homebrew

```zsh
brew bundle
```

### Symbolic link

```zsh
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/ssh/config ~/.ssh/config
ln -sf ~/dotfiles/yazi ~/.config/yazi
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/zellij ~/.config/zellij
ln -sf ~/dotfiles/nvim ~/.config/nvim
```

### Yazi plugins

```zsh
bash yazi/install.sh
```
