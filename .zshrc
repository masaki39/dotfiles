# PATH
export PATH="$(brew --prefix)/bin:$PATH"
export EDITOR='nvim'
export VISUAL='nvim'
export OBSIDIAN_DIR="$HOME/Documents/masaki39-core"

# edit-command-line (Esc -> e) 
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '\ee' edit-command-line

# beginning search history ( up-line and down-line )
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# aliases
alias ze="$EDITOR $HOME/.zshrc"
alias zs="source $HOME/.zshrc"
alias home="cd $HOME"
alias down="cd $HOME/Downloads"
alias desk="cd $HOME/Desktop"
alias dot="cd $HOME/dotfiles"
alias dev="cd $HOME/dev"
alias oo="cd $OBSIDIAN_DIR"
alias oc="cd $OBSIDIAN_DIR/.obsidian/plugins/obsidian-crystal"
alias os="cd $OBSIDIAN_DIR/.obsidian/snippets"
alias oa="cd $OBSIDIAN_DIR && claude"
alias gr='cd "$(git_root)"'
alias gg="lazygit"
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias zx='cd "$(git_root)" && zellij --layout welcome'
alias zz='cd "$(git_root)" && zellij --layout dev'
alias zc='cd "$(git_root)" && zellij --layout code'
alias p='nvim "/tmp/prompt_$(date +%Y%m%d%H%M%S).md" -c startinsert -c "autocmd VimLeave * silent! %y +"'

# git_root: get git root directory, fallback to current directory if not in a git repo
function git_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# devcontainer
function dvc() {
	if ! docker info >/dev/null 2>&1; then
		echo "Docker Desktop is not running. Starting..."
		open -a Docker
		while ! docker info >/dev/null 2>&1; do
			sleep 1
		done
		echo "Docker Desktop started."
	fi
	devcontainer up --workspace-folder . && \
	devcontainer exec --workspace-folder . /bin/bash
}

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# fzf
source <(fzf --zsh)
# starship
eval "$(starship init zsh)"
# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# fastfetch 
fastfetch
