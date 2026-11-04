ユーザーの入力が曖昧な場合はAskUserQuestionを積極的に使ってください。
Node.jsのパッケージマネージャーはnpmではなくpnpmを優先して使ってください。
npxのかわりにpnpm dlxを使ってください。

## Python実行
- `pip3 install`禁止。`uvx --with <pkg> python3 script.py` を使うこと

## 別ディレクトリ/別リポジトリでの作業
- 作業単位が大きい場合は、herdr で当該ディレクトリのペインに別エージェント
  (Claude Code) を起動して任せる。着手前に `herdr --skill` を読む。
- 複数エージェントを指揮するときは、配下のエージェントを別タブ (`herdr tab create`) に起動し、
  メインタブ (ユーザーと話している指揮役のタブ) は自分1つだけにする。
- 完了後は自己報告を鵜呑みにせず `git diff` で検証する。

## pCloud
- pCloudはファイルの保管場所として使われているので、読み取り専用。
- 編集が必要な場合はDownloadsフォルダなどの一時ディレクトリで行う。
- 更新はユーザーに依頼する。

## CLIツール
- ファイル検索は `find` ではなく `fd`、テキスト検索は `grep` ではなく `rg` を使う
  (コマンド先頭の find/grep は PreToolUse フックでブロックされる。パイプ後の grep は可)。
