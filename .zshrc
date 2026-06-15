# PATH
export BREW_PREFIX="/opt/homebrew"
export PATH="$BREW_PREFIX/bin:$PATH"
export EDITOR='nvim'
export VISUAL='nvim'

# history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS      # 重複コマンドを記録しない
setopt HIST_IGNORE_ALL_DUPS  # 履歴全体から重複を削除
setopt HIST_IGNORE_SPACE     # スペース始まりのコマンドを記録しない
setopt HIST_REDUCE_BLANKS    # 余分な空白を削除して記録
setopt SHARE_HISTORY         # セッション間で履歴を共有

# edit-command-line (Esc -> e)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^G' edit-command-line

# beginning search history ( up-line and down-line )
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# plugins
[[ -f ~/.cache/fzf-zsh.zsh ]] || fzf --zsh > ~/.cache/fzf-zsh.zsh
source ~/.cache/fzf-zsh.zsh
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_DEFAULT_OPTS="
  --prompt='🔍️'
  --ghost='search...'
  --layout=reverse
  --style full:double
  --border
  --highlight-line
  --cycle
  --tiebreak=index
  --info=right
  --info-command=''
  --separator='―'
  --border-label ' FZF ' --list-label ' Result ' --preview-label ' Preview '
  --color 'bg:#1a1b26,bg+:#24283b,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7dcfff,border:#7aa2f7,label:#7aa2f7,list-border:#9ece6a,list-label:#9ece6a,preview-border:#bb9af7,preview-label:#bb9af7,input-border:#7dcfff,input-label:#7dcfff,header-border:#e0af68,header-label:#e0af68,footer:#f7768e,footer-border:#f7768e,footer-label:#f7768e,pointer:#ff9e64,marker:#9ece6a,gutter:#1a1b26,prompt:#7aa2f7,query:#c0caf5,info:#c0caf5,spinner:#ff9e64'
"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# load configs
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/functions.zsh
source ~/.config/zsh/env.zsh
# ghq-fzf
export GHQ_FZF_FUNC='g'
source /opt/homebrew/share/ghq-fzf/init.zsh

# zsh-syntax-highlighting (must be last)
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
