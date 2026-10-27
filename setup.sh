#!/bin/bash

set -e

DOTFILES="$HOME/ghq/github.com/masaki39/dotfiles"
STATUSLINE_REPO="$HOME/ghq/github.com/masaki39/ClaudeCodeStatusLine"

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homebrew/install/HEAD/install.sh)"
fi
# インストール直後はこのプロセスの PATH に brew が無いので通す
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages
brew bundle --file="$DOTFILES/Brewfile"

# pnpm グローバルパッケージ (difit, nli など)
xargs pnpm add -g < "$DOTFILES/pnpm/global-packages.txt"

# Claude Code (ネイティブ版)
command -v claude >/dev/null || [ -x ~/.local/bin/claude ] || curl -fsSL https://claude.ai/install.sh | bash

# Create directories
mkdir -p ~/.config ~/.ssh ~/.claude
chmod 700 ~/.ssh

# Symbolic links (force overwrite)
ln -sf "$DOTFILES/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.zshenv" ~/.zshenv
ln -sf "$DOTFILES/.zprofile" ~/.zprofile
ln -sf "$DOTFILES/ssh/config" ~/.ssh/config
ln -sfn "$DOTFILES/yazi" ~/.config/yazi
ln -sfn "$DOTFILES/ghostty" ~/.config/ghostty
ln -sfn "$DOTFILES/nvim" ~/.config/nvim
ln -sfn "$DOTFILES/hammerspoon" ~/.hammerspoon
ln -sfn "$DOTFILES/zsh" ~/.config/zsh
ln -sfn "$DOTFILES/lazygit" ~/.config/lazygit
ln -sfn "$DOTFILES/pnpm" ~/.config/pnpm
ln -sfn "$DOTFILES/uv" ~/.config/uv
ln -sfn "$DOTFILES/git" ~/.config/git
ln -sfn "$DOTFILES/jinrai" ~/.config/jinrai
ln -sfn "$DOTFILES/pplyz" ~/.config/pplyz
# pnpm dlx skills -g のインストール先
ln -sfn "$DOTFILES/agents" ~/.agents
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# statusline は別リポジトリ(ClaudeCodeStatusLine fork)で保守。mascot.sh も同階層に必要
[ -d "$STATUSLINE_REPO" ] || ghq get git@github.com:masaki39/ClaudeCodeStatusLine || echo "warn: ClaudeCodeStatusLine を取得できなかった (SSH 鍵を確認)"
ln -sf "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
ln -sf "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
# ~/.claude/skills は実ディレクトリ (skills CLI もここにリンクを作る) にし、各スキルをリンクする
[ -L ~/.claude/skills ] && rm ~/.claude/skills  # 旧形式 (ディレクトリごとのリンク) から移行
mkdir -p ~/.claude/skills
for skill in "$DOTFILES"/claude/skills/*/ "$DOTFILES"/agents/skills/*/; do
  dst=~/.claude/skills/$(basename "$skill")
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "skip: $dst は実ディレクトリ"
    continue
  fi
  ln -sfn "${skill%/}" "$dst"
done
mkdir -p ~/.claude/hooks
for hook in "$DOTFILES"/claude/hooks/*.sh; do
  ln -sf "$hook" ~/.claude/hooks/
done
# karabiner.ts が ~/.config/karabiner/karabiner.json に直接書き込む (リンク不要)
# Karabiner 未起動だとファイルが無く build が失敗するので最小構成を作っておく
mkdir -p ~/.config/karabiner
[ -s ~/.config/karabiner/karabiner.json ] ||
  echo '{"profiles":[{"name":"Default profile","selected":true,"complex_modifications":{"rules":[]}}]}' > ~/.config/karabiner/karabiner.json
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
