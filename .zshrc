export EDITOR='nvim'
export VISUAL='nvim'

# history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS  # drop older duplicates from the whole history
setopt HIST_IGNORE_SPACE     # do not record commands starting with a space
setopt HIST_REDUCE_BLANKS    # trim extra blanks before recording
setopt SHARE_HISTORY         # share history across sessions

# edit-command-line (Ctrl-G)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^G' edit-command-line

# beginning search history ( up-line and down-line )
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# completion (full check once a day, cached otherwise)
autoload -Uz compinit
_zcompdump_old=(~/.zcompdump(N.mh+24))
if (( $#_zcompdump_old )) || [[ ! -f ~/.zcompdump ]]; then compinit; else compinit -C; fi
unset _zcompdump_old
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# plugins
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
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
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# load configs
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/functions.zsh
[[ -f ~/.config/zsh/local.zsh ]] && source ~/.config/zsh/local.zsh  # machine-specific (gitignored)
source ~/.config/zsh/secrets.zsh   # export API keys from the Keychain
# ghq-fzf
export GHQ_FZF_FUNC='gv'
[[ -f $HOMEBREW_PREFIX/share/ghq-fzf/init.zsh ]] && source "$HOMEBREW_PREFIX/share/ghq-fzf/init.zsh"

# zsh-syntax-highlighting (must be last)
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
