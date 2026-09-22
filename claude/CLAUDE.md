ユーザーの入力が曖昧な場合はAskUserQuestionを積極的に使ってください。
Node.jsのパッケージマネージャーはnpmではなくpnpmを優先して使ってください。
npxのかわりにpnpm dlxを使ってください。

## Python実行
- `pip3 install`禁止。`uvx --with <pkg> python3 script.py` を使うこと

## 別ディレクトリ/別リポジトリでの作業
- ユーザーに依頼されたら、herdr で当該ディレクトリのペインに別エージェント
  (Claude Code) を起動して任せる。着手前に `herdr --skill` を読む。
- 指示文には背景・数値・対象ファイル/行・変更前後・禁止事項(コミット禁止等)を
  前もって全部入れ、判断ポイントを潰す。
- 別エージェントが blocked (承認/質問) になったら自分で答えず、内容をユーザーに確認する。
- 複数エージェントを指揮するときは、配下のエージェントを別タブ (`herdr tab create`) に起動し、
  メインタブ (ユーザーと話している指揮役のタブ) は自分1つだけにする。
- 完了後は自己報告を鵜呑みにせず `git diff` で検証する。

## difit
- `--background` で起動したら、出力JSONの `url` を続けて `open <url>` でブラウザに開く
  (ユーザーが手動で開かなくて済むように)。スキル本体は書き換えない。

## pptxスライド作成 (pptxスキル)
- LibreOffice変換で日本語が消えたら、まず `FONTCONFIG_FILE=/opt/homebrew/etc/fonts/fonts.conf`
  を明示する。それでも出ない場合はヒラギノ(.ttc)をLibreOfficeが解釈できないケースなので、
  Noto Sans JP を用意して自前のfonts.confでフォールバックさせる。
- pptxgenjsは `<a:ea>` を書かないためグラフ内の日本語だけ脱落する。生成後にchart XMLへ
  East Asianフォントを注入し、完成前にPDF/PNGで豆腐・欠落を必ず目視確認する。
