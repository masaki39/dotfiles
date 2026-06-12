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

# dev layout
function dev() {
  osascript << 'EOF'
tell application "Ghostty"
  set mainTerm to focused terminal of selected tab of front window
  set cmdTerm to split mainTerm direction right
  set gitTerm to split cmdTerm direction down
  input text "yazi\n" to mainTerm
  input text "claude\n" to cmdTerm
  input text "lazygit\n" to gitTerm
  tell mainTerm to focus
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
