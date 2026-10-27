# Location of this repository (~/.zshenv is a symlink to the .zshenv in it)
export DOTFILES=${${(%):-%x}:A:h}
# uv
export PATH="$HOME/.local/bin:$PATH"
# Application Support
export XDG_CONFIG_HOME=${HOME}/.config
