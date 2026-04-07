alias ze="$EDITOR $HOME/.zshrc"
alias zs="source $HOME/.zshrc"
alias ls='eza --icons --group-directories-first'
alias gr='cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'
alias gg="lazygit"
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias p='nvim "/tmp/prompt_$(date +%Y%m%d%H%M%S).md" -c startinsert -c "autocmd VimLeave * silent! %y +"'
alias ghi='gh search issues --owner masaki39 --state open'
alias cl='claude --enable-auto-mode'

# expand alias on enter (must be after plugins)
expand-alias-and-accept-line() {
  local words=(${(z)BUFFER})
  if [[ -n ${aliases[$words[1]]} ]]; then
    BUFFER="${aliases[$words[1]]}${BUFFER#${words[1]}}"
    CURSOR=$#BUFFER
  fi
  zle .accept-line
}
zle -N accept-line expand-alias-and-accept-line
