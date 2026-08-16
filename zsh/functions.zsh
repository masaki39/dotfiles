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

# backup a directory to external storage via rsync mirror (--delete, no excludes)
# usage: backup [-n|--dry-run] [src] [dest_base]
#   defaults to $BACKUP_SRC / $BACKUP_DEST_BASE (set in env.zsh)
#   dest is dest_base/$(basename src)
function backup() {
	local usage="Usage: backup [-n|--dry-run] [src] [dest_base]
  defaults to \$BACKUP_SRC / \$BACKUP_DEST_BASE (set in env.zsh)
  dest is dest_base/\$(basename src)"

	local dry_run="" args=()
	for arg in "$@"; do
		case "$arg" in
			-h|--help)
				echo "$usage"
				return 0
				;;
			-n|--dry-run)
				dry_run="--dry-run"
				;;
			*)
				args+=("$arg")
				;;
		esac
	done

	local src="${args[1]:-$BACKUP_SRC}"
	local dest_base="${args[2]:-$BACKUP_DEST_BASE}"

	if [[ -z "$src" || -z "$dest_base" ]]; then
		echo "$usage" >&2
		return 1
	fi
	if [[ ! -d "$src" ]]; then
		echo "Source not found: $src" >&2
		return 1
	fi
	if [[ ! -d "$dest_base" ]]; then
		echo "Destination base not found (drive not mounted?): $dest_base" >&2
		return 1
	fi

	local dest="${dest_base%/}/$(basename "$src")"
	[[ -z "$dry_run" ]] && mkdir -p "$dest"

	rsync -a --delete $dry_run --info=progress2 --no-inc-recursive "${src%/}/" "$dest/" && \
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup ${dry_run:+(dry-run) }done: $src -> $dest"
}

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
