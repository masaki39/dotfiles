alias ze="$EDITOR $HOME/.zshrc"
alias zs='exec zsh'
alias dot='cd "$HOME/ghq/github.com/masaki39/dotfiles"'
alias kb='(cd "$HOME/ghq/github.com/masaki39/dotfiles/karabiner" && pnpm build)'
alias ls='eza --icons --group-directories-first'
alias lt='eza --icons --group-directories-first --git-ignore -DTL 3'
alias gr='cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'
alias gg="lazygit"
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias p='nvim "/tmp/prompt_$(date +%Y%m%d%H%M%S).md" -c startinsert -c "autocmd VimLeave * silent! %y +"'
alias ghi='gh search issues --owner @me --state open'
alias ghp='gh search prs --owner @me --state open'
alias cl='claude'
alias n='nvim'
alias nosleep="sudo pmset -a disablesleep 1"
alias oksleep="sudo pmset -a disablesleep 0"
alias he='herdr'
alias hes='herdr server stop'
alias hel='herdr session list'
alias skills='pnpm dlx skills'
alias oo='open -a Obsidian'

# expand alias on enter (must be after plugins)
expand-alias-and-accept-line() {
  local words=(${(z)BUFFER})
  if [[ -n ${aliases[$words[1]]} ]]; then
    # 先頭の空白は残す (HIST_IGNORE_SPACE を効かせるため)
    local lead=${BUFFER%%[^[:space:]]*}
    local rest=${BUFFER#$lead}
    BUFFER="${lead}${aliases[$words[1]]}${rest#${words[1]}}"
    CURSOR=$#BUFFER
  fi
  zle .accept-line
}
zle -N accept-line expand-alias-and-accept-line
