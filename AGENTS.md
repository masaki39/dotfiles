# AGENTS.md

This repository is a complete development environment for macOS (Apple Silicon). When an agent is given
this URL (`https://github.com/masaki39/dotfiles`), it reproduces the environment on a new Mac as follows.

## Reproduction steps

1. **Check prerequisites**
   - `uname -sm` must print `Darwin arm64` (Homebrew is assumed to live in `/opt/homebrew`).
   - If `brew` is missing, installing Homebrew needs the sudo password. If `sudo -n true` fails,
     the agent cannot install it, so ask the user to run this in their own terminal
     (it also installs the Command Line Tools):
     ```sh
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
2. **Fetch** (git comes with the Command Line Tools; follow the ghq layout)
   ```sh
   git clone https://github.com/masaki39/dotfiles ~/ghq/github.com/masaki39/dotfiles
   ```
3. **Set up** (idempotent; if it fails midway, fix the cause and run it again)
   ```sh
   bash ~/ghq/github.com/masaki39/dotfiles/setup.sh
   ```
   - Existing real files are moved to `<name>.bak.<timestamp>` before being replaced by links.
   - Some casks (Karabiner, Google Japanese Input, Microsoft Office, etc.) ask for sudo through a pkg
     installer. If one fails, ask the user to run `brew install --cask <name>` for it, then re-run.
4. **Verify** (same checks as the Verify steps in `.github/workflows/setup.yml`)
   ```sh
   zsh -lic 'whence -p brew pnpm difit fzf starship yazi nvim zoxide && print SHELL_OK'
   ```
   It passes if `SHELL_OK` is printed and no `command not found` appears.

## Manual steps for the user

An agent cannot finish these. When done, hand the user this list.

- [ ] SSH key: `ssh-keygen -t ed25519` → `gh auth login -p ssh` (browser auth).
      `.gitconfig` rewrites `https://github.com/` to SSH, so pushing and fetching private repos fail until this is done
- [ ] Accessibility permission: Hammerspoon, Karabiner-Elements, Homerow, Ghostty
- [ ] Add Google Japanese Input as an input source
- [ ] Secrets: register keys marked `!` in `secret ls` with `secret set <KEY>` (the user types the values; agents never guess or generate them)
- [ ] Machine-specific settings: `cp zsh/local.zsh.example zsh/local.zsh` and fill it in (only if needed)
- [ ] Raycast: Settings → Advanced → Import `raycast/Raycast.rayconfig`

## Machine-specific values

- Never hard-code the repository location. Shell code uses `$DOTFILES` (`.zshenv` derives it from its own
  link target); scripts derive it from their own location. LaunchAgent plists contain `__DOTFILES__`,
  which `setup.sh` substitutes when installing them.
- Secrets live in the macOS Keychain (`zsh/secrets.zsh`). Never write them to files or commit them.
- Non-secret machine-specific values go in `zsh/local.zsh` (gitignored). This is a public repository, so never commit real paths.

## When changing things

- When adding a new config directory, add it to both the `link` calls in `setup.sh` and the CI "Verify links" step.
- `scripts/auto-update.sh` runs `brew bundle dump` monthly and auto-commits the `Brewfile`.
- Claude Code writes back to `claude/settings.json` at runtime, so the working tree may be dirty.
- Write comments, docs, and messages in English.
