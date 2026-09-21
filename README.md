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
secret-set HF_TOKEN   # 登録・更新 (値は対話入力)
secret HF_TOKEN       # 1 つ取り出して標準出力へ
```

鍵を増やすときは `zsh/secrets.zsh` の `_SECRET_KEYS` に名前を足す。
マシン固有のパス等は `zsh/local.zsh.example` を `zsh/local.zsh` にコピーして書く (gitignore)。
Hammerspoon 側 (`hammerspoon/Spoons/Muryokusho.spoon/keychain.lua`) も同じ
Keychain を読んでいる。

