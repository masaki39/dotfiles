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

## Secrets

API キーは平文ファイルではなく macOS Keychain に置く (`zsh/secrets.zsh`)。
シェル起動時に Keychain から読んで export されるので、普段は何も叩かなくてよい。

```zsh
secret set HF_TOKEN   # 登録・更新 (値は対話入力)
printf %s "$v" | secret set HF_TOKEN   # 標準入力から登録 (エージェント等の非対話用)
secret get HF_TOKEN   # 1 つ取り出して標準出力へ (secret HF_TOKEN でも可)
secret rm HF_TOKEN    # 削除 (このシェルからも unset)
secret ls             # 登録済みの鍵名とプロジェクト名を一覧 (値は出さない)
secret ls projA       # projA の鍵名を一覧
```

鍵を増やすときは `zsh/secrets.zsh` の `_SECRET_KEYS` に名前を足す。

特定のプロジェクトだけで使う鍵は `<PROJ>/<KEY>` の名前で登録し、実行時に明示して渡す
(`_SECRET_KEYS` には足さないので常時 export はされない)。同じ変数名をプロジェクトごとに使い分けられる。

```zsh
secret set projA/OPENAI_API_KEY
secret exec projA -- uv run main.py   # OPENAI_API_KEY として渡る (このシェルには残らない)
secret load projA                     # このシェルに export する
secret rm projA/                      # projA の鍵をすべて削除
```

マシン固有のパス等は `zsh/local.zsh.example` を `zsh/local.zsh` にコピーして書く (gitignore)。
Hammerspoon 側 (`hammerspoon/Spoons/Muryokusho.spoon/keychain.lua`) も同じ
Keychain を読んでいる。

