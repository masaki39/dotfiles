#!/bin/bash

set -eo pipefail

[ "$(uname -sm)" = "Darwin arm64" ] || { echo "setup.sh requires macOS on Apple Silicon (Darwin arm64)" >&2; exit 1; }

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
brew bundle --file="$DOTFILES/Brewfile"

# pnpm global packages (difit, etc.). .zprofile is not in effect yet, so set PATH here
mkdir -p ~/.config
# Apply minimumReleaseAge (pnpm/config.yaml) before the global install
link "$DOTFILES/pnpm" ~/.config/pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
xargs pnpm add -g < "$DOTFILES/pnpm/global-packages.txt"

# Claude Code (native build). Unpinned on purpose: first-party installer, and Claude Code self-updates
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
link "$DOTFILES/starship/starship.toml" ~/.config/starship.toml
link "$DOTFILES/claude/settings.json" ~/.claude/settings.json
link "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# The statusline lives in a separate repo (ClaudeCodeStatusLine fork); mascot.sh must sit next to it
# Public repo, cloned over HTTPS (.gitconfig only rewrites pushes to SSH, so no key is needed)
[ -d "$STATUSLINE_REPO" ] || git clone "$STATUSLINE_URL" "$STATUSLINE_REPO"
link "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
link "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
# ~/.claude/skills is a real directory; link each skill individually
[ -L ~/.claude/skills ] && rm ~/.claude/skills  # migrate from the old layout (whole-directory link)
mkdir -p ~/.claude/skills
for skill in "$DOTFILES"/claude/skills/*/; do
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

# Install yazi plugins
bash "$DOTFILES/yazi/install.sh"

# Menu bar shortcuts (keys are menu item titles, so they must match the app's Japanese UI)
defaults write com.google.Chrome NSUserKeyEquivalents '{
    "他のタブをすべて閉じる" = "@~w";
}'

echo "✓ Setup complete!"
