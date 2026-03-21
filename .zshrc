# PATH
export BREW_PREFIX="$(brew --prefix)"
export PATH="$BREW_PREFIX/bin:$PATH"
export EDITOR='nvim -c startinsert'
export VISUAL='nvim -c startinsert'

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
bindkey '\ee' edit-command-line

# beginning search history ( up-line and down-line )
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# plugins
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f'
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# load configs
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/functions.zsh
source ~/.config/zsh/env.zsh

# zsh-syntax-highlighting (must be last)
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
