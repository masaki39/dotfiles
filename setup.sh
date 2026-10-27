#!/bin/bash

set -e

# DOTFILES_CI=1: CI 用。cask と LaunchAgent の登録を飛ばす
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 既存の実ファイル/実ディレクトリは <name>.bak.<日時> に退避してからリンクする
link() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    mv "$2" "$2.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $2"
  fi
  ln -sfn "$1" "$2"
}

# pnpm などが ~/.config を読むように (.zshenv はまだ効いていない)
export XDG_CONFIG_HOME="$HOME/.config"
STATUSLINE_REPO="$HOME/ghq/github.com/masaki39/ClaudeCodeStatusLine"

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homebrew/install/HEAD/install.sh)"
fi
# インストール直後はこのプロセスの PATH に brew が無いので通す
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages
# uv tool は brew bundle が環境変数を渡さず最新 Python で入れてしまい、依存のビルドが
# 通らないことがあるので、Brewfile から外して後で Python を固定して入れる
skip='^uv '
[ -n "${DOTFILES_CI:-}" ] && skip='^(uv|cask) '
BREWFILE=$(mktemp)
grep -Ev "$skip" "$DOTFILES/Brewfile" > "$BREWFILE"
brew bundle --file="$BREWFILE"
sed -n 's/^uv "\([^"]*\)".*/\1/p' "$DOTFILES/Brewfile" | while read -r tool; do
  uv tool install --python 3.13 "$tool"
done

# pnpm グローバルパッケージ (difit, nli など)。.zprofile が効く前なのでここで通す
mkdir -p ~/.config
# minimumReleaseAge (pnpm/config.yaml) をグローバルインストール前に効かせる
link "$DOTFILES/pnpm" ~/.config/pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
xargs pnpm add -g < "$DOTFILES/pnpm/global-packages.txt"

# Claude Code (ネイティブ版)
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
# pnpm dlx skills -g のインストール先
link "$DOTFILES/agents" ~/.agents
link "$DOTFILES/claude/settings.json" ~/.claude/settings.json
link "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
# statusline は別リポジトリ(ClaudeCodeStatusLine fork)で保守。mascot.sh も同階層に必要
[ -d "$STATUSLINE_REPO" ] || ghq get git@github.com:masaki39/ClaudeCodeStatusLine || echo "warn: ClaudeCodeStatusLine を取得できなかった (SSH 鍵を確認)"
link "$STATUSLINE_REPO/statusline.sh" ~/.claude/statusline.sh
link "$STATUSLINE_REPO/mascot.sh" ~/.claude/mascot.sh
# ~/.claude/skills は実ディレクトリ (skills CLI もここにリンクを作る) にし、各スキルをリンクする
[ -L ~/.claude/skills ] && rm ~/.claude/skills  # 旧形式 (ディレクトリごとのリンク) から移行
mkdir -p ~/.claude/skills
for skill in "$DOTFILES"/claude/skills/*/ "$DOTFILES"/agents/skills/*/; do
  link "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done
mkdir -p ~/.claude/hooks
for hook in "$DOTFILES"/claude/hooks/*.sh; do
  link "$hook" ~/.claude/hooks/"$(basename "$hook")"
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

if [ -n "${DOTFILES_CI:-}" ]; then
  echo "✓ Setup complete! (CI: LaunchAgents skipped)"
  exit 0
fi

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
