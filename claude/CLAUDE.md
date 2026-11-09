## 原則
- 日本語で応答すること。
- ユーザーの入力が曖昧な場合はAskUserQuestionを積極的に使ってください。
- Node.jsのパッケージマネージャーはnpmではなくpnpmを優先して使ってください。
- npxのかわりにpnpm dlxを使ってください。
- Pythonの実行では`pip3 install`禁止。`uvx --with <pkg> python3 script.py` を使うこと

## pCloud
- pCloudはファイルの保管場所として使われているので、読み取り専用。
- 編集が必要な場合はDownloadsフォルダなどの一時ディレクトリで行う。
- 更新はユーザーに依頼する。

## CLIツール
- ファイル検索は `find` ではなく `fd`、テキスト検索は `grep` ではなく `rg` を使う
  (コマンド先頭の find/grep は PreToolUse フックでブロックされる。パイプ後の grep は可)。
