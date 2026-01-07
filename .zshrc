# alias
alias ze="micro ~/.zshrc"
alias zs="source ~/.zshrc"
alias down="cd /Users/masaki/Downloads"
alias ccc="cd /Users/masaki/Documents/masaki39-core/.obsidian/plugins/obsidian-crystal"
alias css="cd /Users/masaki/Documents/masaki39-core/.obsidian/snippets"
alias ooo="cd /Users/masaki/Documents/masaki39-core && claude"
alias obsidian="cd /Users/masaki/Documents/masaki39-core"

## uv系
alias main='uv run python main.py'
alias ppget="uvx ppget"

# starship
eval "$(starship init zsh)"

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

fastfetch
