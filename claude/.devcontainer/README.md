# Claude Code Sandbox Devcontainer

公式リポジトリからそのまま取得した Claude Code 用 devcontainer 定義。

- **取得元**: https://github.com/anthropics/claude-code/tree/main/.devcontainer
- **ドキュメント**: https://docs.anthropic.com/en/docs/claude-code/devcontainer

## ファイル構成

| ファイル | 内容 |
|---------|------|
| `devcontainer.json` | コンテナ設定（Node.js 20、VS Code拡張、ボリューム等） |
| `Dockerfile` | イメージ定義（Claude Code CLI、zsh、git-delta等） |
| `init-firewall.sh` | 起動時ファイアウォール設定（許可リスト方式） |

## 更新方法

```bash
cd ~/.devcontainer  # またはこのディレクトリ
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/devcontainer.json
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/Dockerfile
curl -O https://raw.githubusercontent.com/anthropics/claude-code/main/.devcontainer/init-firewall.sh
```
