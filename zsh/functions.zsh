# ghq fzf
function gv() {
  local root=$(ghq root)
  local target=$(ghq list | fzf \
    --preview "eza --tree --color=always --icons --level=2 '$root/{}'" \
    --preview-window=right:60%)
  if [ -n "$target" ]; then
    cd "$root/$target"
  fi
}

function gb() {
  local selected=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | \
    fzf --prompt "gh repo: " \
        --preview "gh repo view {} | bat --color=always --style=plain --language=markdown" \
        --preview-window=right:60%:wrap)

  [ -n "$selected" ] && gh repo view -w "$selected"
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

# devcontainer + claude
function dvcc() {
	if ! docker info >/dev/null 2>&1; then
		echo "Docker Desktop is not running. Starting..."
		open -a Docker
		while ! docker info >/dev/null 2>&1; do
			sleep 1
		done
		echo "Docker Desktop started."
	fi
	devcontainer up --workspace-folder . && \
	devcontainer exec --workspace-folder . claude --permission-mode plan --allow-dangerously-skip-permissions
}

# dev layout (yazi + claude + lazygit)
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
