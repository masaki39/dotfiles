# PATH
export PATH="$(brew --prefix)/bin:$PATH"
export EDITOR='nvim'
export VISUAL='nvim'
export OBSIDIAN_DIR='~/Documents/masaki39-core'

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

# alias
alias ze="$EDITOR ~/.zshrc"
alias zs="source ~/.zshrc"
alias home="cd ~"
alias down="cd ~/Downloads"
alias desk="cd ~/Desktop"
alias dot='cd ~/dotfiles'
alias dev='cd ~/dev'
alias obsidian="cd $OBSIDIAN_DIR"
alias ccc="cd $OBSIDIAN_DIR/.obsidian/plugins/obsidian-crystal"
alias css="cd $OBSIDIAN_DIR/.obsidian/snippets"
alias ooo="cd $OBSIDIAN_DIR && claude"
alias gr='cd "$(git rev-parse --show-toplevel)"'
alias gg="lazygit"
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias zz='cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && zellij --layout dev'
alias p='nvim "/tmp/prompt_$(date +%Y%m%d%H%M%S).md" -c startinsert -c "autocmd VimLeave * silent! %y +"'

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
