# ghq / gh fzf
function g() {
  local root=$(ghq root)
  local result=$(ghq list | fzf \
    --prompt "ghq> " \
    --header "Enter:cd  C-g:GitHub" \
    --layout=reverse \
    --border=rounded \
    --height=80% \
    --preview "eza --tree --color=always --icons --level=2 --git-ignore '$root/{}'" \
    --preview-window=right:40%:border-left \
    --bind "ctrl-g:execute-silent(gh repo view --web {})")
  [ -n "$result" ] && cd "$root/$result"
}

function gb() {
  local selected=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | fzf \
    --prompt "gh> " \
    --header "Enter:open" \
    --layout=reverse \
    --border=rounded \
    --height=80% \
    --preview "gh repo view {} | bat --color=always --style=plain --language=markdown" \
    --preview-window=right:40%:border-left:wrap)
  [ -n "$selected" ] && gh repo view --web "$selected"
}

# devcontainer
function dvc() {
	if ! colima status >/dev/null 2>&1; then
		echo "Colima is not running. Starting..."
		colima start
	fi
	local config_args=()
	if [[ ! -f ".devcontainer/devcontainer.json" && ! -f ".devcontainer.json" ]]; then
		echo "No local devcontainer config found. Using global config."
		config_args=("--config" "$HOME/ghq/github.com/masaki39/dotfiles/claude/.devcontainer/devcontainer.json")
	fi
	devcontainer up --workspace-folder . "${config_args[@]}" && \
	devcontainer exec --workspace-folder . "${config_args[@]}" sh -c 'exec "${SHELL:-sh}"'
}

# devcontainer + claude
function dvcc() {
	if ! colima status >/dev/null 2>&1; then
		echo "Colima is not running. Starting..."
		colima start
	fi
	local config_args=()
	if [[ ! -f ".devcontainer/devcontainer.json" && ! -f ".devcontainer.json" ]]; then
		echo "No local devcontainer config found. Using global config."
		config_args=("--config" "$HOME/ghq/github.com/masaki39/dotfiles/claude/.devcontainer/devcontainer.json")
	fi
	devcontainer up --workspace-folder . "${config_args[@]}" && \
	devcontainer exec --workspace-folder . "${config_args[@]}" claude --permission-mode plan --allow-dangerously-skip-permissions
}

# dev layout (yazi + lazygit | claude + terminal)
function dev() {
  osascript << 'EOF'
tell application "Ghostty"
  set mainTerm to focused terminal of selected tab of front window
  set rightTop to split mainTerm direction right
  set leftBottom to split mainTerm direction down
  set rightBottom to split rightTop direction down
  perform action "resize_split:down,9999" on rightBottom
  perform action "resize_split:up,100" on rightBottom
  input text "yazi\n" to mainTerm
  input text "lazygit\n" to leftBottom
  input text "claude\n" to rightTop
  tell rightTop to focus
end tell
EOF
}

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
