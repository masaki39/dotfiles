# Homebrew (PATH, HOMEBREW_PREFIX, etc.)
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
