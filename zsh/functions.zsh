# devcontainer
function dvc() {
	if ! colima status >/dev/null 2>&1; then
		echo "Colima is not running. Starting..."
		colima start
	fi
	local config_args=()
	if [[ ! -f ".devcontainer/devcontainer.json" && ! -f ".devcontainer.json" ]]; then
		echo "No local devcontainer config found. Using global config."
		config_args=("--config" "$DOTFILES/claude/.devcontainer/devcontainer.json")
	fi
	devcontainer up --workspace-folder . "${config_args[@]}" && \
	devcontainer exec --workspace-folder . "${config_args[@]}" sh -c 'exec "${SHELL:-sh}"'
}

# dev layout
function dv() {
  osascript << 'EOF'
tell application "Ghostty"
  set mainTerm to focused terminal of selected tab of front window
  set subTerm to split mainTerm direction right
  input text "herdr\n" to mainTerm
  input text "y\n" to subTerm
  tell subTerm to focus
end tell
EOF
}

# backup a directory to external storage via rsync mirror (--delete, excludes only ._* sidecars)
# usage: backup [-n|--dry-run] [src] [dest_base]
#   defaults to $BACKUP_SRC / $BACKUP_DEST_BASE (set in local.zsh)
#   dest is dest_base/$(basename src); deleted/overwritten files go to dest_base/.deleted/
function backup() {
	local usage="Usage: backup [-n|--dry-run] [src] [dest_base]
  defaults to \$BACKUP_SRC / \$BACKUP_DEST_BASE (set in local.zsh)
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

	# Normalize to an absolute path so that ., .., or / cannot make dest equal dest_base itself
	src=${src:A}
	dest_base=${dest_base:A}
	local name=${src:t}
	if [[ -z $name || $name == / ]]; then
		echo "Invalid source: $src" >&2
		return 1
	fi
	local dest="$dest_base/$name"
	if [[ $dest == $src || $dest == $src/* ]]; then
		echo "Destination is inside source: $dest" >&2
		return 1
	fi
	# Mirroring into a parent of src would --delete src itself
	if [[ $src == $dest/* ]]; then
		echo "Source is inside destination: $src" >&2
		return 1
	fi
	[[ -z "$dry_run" ]] && mkdir -p "$dest"

	# Deleted or overwritten files are moved to dest_base/.deleted/<name>/<timestamp>/
	local trash="$dest_base/.deleted/$name/$(date '+%Y%m%d-%H%M%S')"
	# exFAT lists names as NFD and creates ._* sidecars, so --delete would treat both as extras
	# and move them to .deleted on every run. Protect the NFD spelling of each source name and
	# exclude the sidecars. Do not use --iconv (it corrupts emoji) or --delete-after (it drops
	# the NFD files from the mirror).
	local rules
	rules=$(mktemp -t backup-filter.XXXXXX) || return 1
	if ! (cd "$src" && find . -mindepth 1 -print0 | perl -CSDA -MUnicode::Normalize -0 -ne '
		chomp;
		next unless m{^\./(.*/)?([^/]+)$}s;
		my ($dir, $base) = ($1 // "", $2);
		my $nfd = NFD($base);
		next if $nfd eq $base;
		my $path = "/$dir$nfd";
		$path =~ s/([\[\]*?\\])/\\$1/g;
		print "P $path\n";
	') > "$rules"; then
		rm -f "$rules"
		echo "Failed to build filter rules" >&2
		return 1
	fi

	rsync -a --delete --exclude='._*' --filter="merge $rules" --backup --backup-dir="$trash" $dry_run --info=progress2 --no-inc-recursive "$src/" "$dest/"
	local rc=$?
	rm -f "$rules"
	(( rc == 0 )) && echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup ${dry_run:+(dry-run) }done: $src -> $dest"
	return $rc
}

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
