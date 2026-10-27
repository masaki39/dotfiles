# dotfiles

## Setup

```zsh
xcode-select --install
git clone https://github.com/masaki39/dotfiles ~/ghq/github.com/masaki39/dotfiles
bash ~/ghq/github.com/masaki39/dotfiles/setup.sh
```

Then:

- [ ] `gh auth login -p ssh`, and re-run `setup.sh` if the statusline clone failed
- [ ] Grant Accessibility to Hammerspoon, Karabiner-Elements, Homerow, and Ghostty
- [ ] Add Google Japanese Input as an input source
- [ ] Register missing secrets (`secret ls` marks them with `!`)
- [ ] Copy `zsh/local.zsh.example` to `zsh/local.zsh` for machine-specific settings
- [ ] Import `raycast/Raycast.rayconfig` from Raycast → Settings → Advanced

## Secrets

API keys live in the macOS Keychain, not in files. Keys listed in `_SECRET_KEYS` (`zsh/secrets.zsh`) are exported on shell startup.

```zsh
secret set HF_TOKEN                   # add or update (prompts, or reads stdin)
secret get HF_TOKEN                   # print one value
secret rm HF_TOKEN                    # delete
secret ls                             # list key names
secret set projA/OPENAI_API_KEY       # project-scoped key (not auto-exported)
secret exec projA -- uv run main.py   # run with projA's keys
```
