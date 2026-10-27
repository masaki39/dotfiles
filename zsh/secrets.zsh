# secrets.zsh
# Keep API keys and the like in the macOS Keychain instead of plain-text files.
# No values live in this file, so it is safe to commit.
#
#   secret set <KEY>   add or update in the Keychain (interactive on a TTY, stdin otherwise)
#   secret get <KEY>   print one value from the Keychain (also: secret <KEY>)
#   secret rm  <KEY>   delete from the Keychain and unset it in this shell (<PROJ>/ deletes a project)
#   secret ls [PROJ]   list key names (never values); with PROJ, list that project's keys
#   secret load [PROJ] re-read from the Keychain and export; with PROJ, that project's keys
#   secret exec <PROJ> -- <cmd...>
#                      export <PROJ>/-prefixed keys without the prefix and run cmd
#   secret help        show usage
#
# Keys are exported automatically when this file is sourced, so normally nothing needs to be run.
# To auto-export another key, add its name to _SECRET_KEYS.
# Project-only keys are stored with `secret set <PROJ>/<KEY>`; do not add them to
# _SECRET_KEYS, pass them with `secret exec <PROJ> -- cmd` instead.

_SECRET_KEYS=(
	CZ_OPENAI_API_KEY
)
_SECRET_PREFIX='dot:'

secret() {
	local cmd=$1
	(( $# )) && shift
	case $cmd in
	get)  _secret_get "$@" ;;
	set)  _secret_set "$@" ;;
	rm)   _secret_rm "$@" ;;
	ls)   _secret_ls "$@" ;;
	load) _secret_load "$@" ;;
	exec) _secret_exec "$@" ;;
	help|-h|--help) _secret_help ;;
	'')   _secret_help >&2; return 2 ;;
	*)    _secret_get "$cmd" ;;
	esac
}

_secret_help() {
	print -r -- 'usage: secret <command> [KEY]

  set  <KEY>   add or update in the Keychain
                 reads a TTY interactively, otherwise stdin (printf %s "$v" | secret set KEY)
  get  <KEY>   print one value from the Keychain (also: secret <KEY>)
  rm   <KEY>   delete from the Keychain and unset it in this shell
  rm   <PROJ>/ delete all keys of that project
  ls [PROJ]    list key names stored in the Keychain (never values)
                 no arg: global keys and project names  PROJ: keys of that project
                 ? = not in _SECRET_KEYS  ! = not in the Keychain
  load [PROJ]  re-read from the Keychain and export
                 PROJ: export <PROJ>/<KEY> as <KEY> in this shell
  exec <PROJ> -- <cmd...>
               export <PROJ>/<KEY> as <KEY> and run cmd
  help         show this help

Keys in _SECRET_KEYS are exported automatically at startup.
Project-only keys are stored with `secret set <PROJ>/<KEY>` (not auto-exported).'
}

_secret_get() {
	[[ -n $1 ]] || { print -u2 'usage: secret get <KEY>'; return 2 }
	security find-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" -w 2>/dev/null
}

# The value is read with hidden input on a TTY, otherwise from stdin (for agents).
# A value passed as an argument would show up in ps, so the command goes to security -i via stdin.
# (security add-generic-password -w is not used because its prompt truncates at 128 chars)
_secret_set() {
	[[ -n $1 && $1 != *[[:space:]\"\\]* ]] ||
		{ print -u2 'usage: secret set <KEY>  (value from stdin or interactive input)'; return 2 }
	local v
	if [[ -t 0 ]]; then
		read -rs "v?$1: " || return 1
		print -u2
	else
		v="$(cat)"
	fi
	[[ -n $v ]] || { print -u2 'secret: empty value'; return 1 }
	[[ $v != *$'\n'* ]] || { print -u2 'secret: value must not contain a newline'; return 1 }
	print -r -- "add-generic-password -U -s \"${_SECRET_PREFIX}$1\" -a \"$USER\" -w \"${${v//\\/\\\\}//\"/\\\"}\"" |
		security -i >/dev/null
	# security -i returns 0 even on failure, so read the value back to verify
	[[ "$(_secret_get $1)" == "$v" ]] || { print -u2 "secret: failed to store $1"; return 1 }
	[[ $1 == */* ]] || _secret_load
}

_secret_rm() {
	[[ -n $1 ]] || { print -u2 'usage: secret rm <KEY> | <PROJ>/'; return 2 }
	# <PROJ>/ deletes every key of that project
	if [[ $1 == */ ]]; then
		local proj=${1%/} k
		[[ -n $proj && $proj != */* ]] || { print -u2 'usage: secret rm <PROJ>/'; return 2 }
		_secret_proj_keys $proj || return
		for k in $reply; do _secret_rm $k || return; done
		return 0
	fi
	security delete-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" >/dev/null || return
	# Project keys (PROJ/KEY) are never exported, so do not unset them
	[[ $1 == */* ]] || unset $1
}

# Print key names stored in the Keychain (without the prefix), one per line.
_secret_stored() {
	security dump-keychain 2>/dev/null |
		sed -n "s/^ *\"svce\"<blob>=\"${_SECRET_PREFIX}\(.*\)\"\$/\1/p" | sort -u
}

# Put the <PROJ>/-prefixed key names into reply. Error if there are none.
_secret_proj_keys() {
	reply=(${(M)${(f)"$(_secret_stored)"}:#$1/*})
	(( $#reply )) ||
		{ print -u2 "secret: no keys stored for $1/ (secret set $1/<KEY>)"; return 1 }
}

# List key names in the Keychain (never values).
# With no argument, show global keys and project names; with <PROJ>, that project's keys.
# Mark differences from _SECRET_KEYS.
_secret_ls() {
	local k p
	local -a stored projs pkeys
	if [[ -n $1 ]]; then
		[[ $1 != */* ]] || { print -u2 'usage: secret ls [PROJ]'; return 2 }
		_secret_proj_keys $1 || return
		for k in $reply; do print -- "  ${k#$1/}"; done
		return 0
	fi
	stored=(${(f)"$(_secret_stored)"})
	for k in ${stored:#*/*}; do
		if (( ${_SECRET_KEYS[(Ie)$k]} )); then
			print -- "  $k"
		else
			print -- "? $k  (not in _SECRET_KEYS, so not auto-exported)"
		fi
	done
	for k in $_SECRET_KEYS; do
		(( ${stored[(Ie)$k]} )) || print -- "! $k  (not stored in the Keychain)"
	done
	projs=(${(u)${(M)stored:#*/*}%%/*})
	for p in $projs; do
		pkeys=(${(M)stored:#$p/*})
		print -- "  $p/  ($#pkeys keys, list with: secret ls $p)"
	done
}

# Run cmd in a subshell with <PROJ>/<KEY> exported as <KEY>.
# Nothing is left behind in the calling shell.
_secret_exec() {
	local proj=$1
	[[ -n $proj && $proj != */* && $2 == -- && $# -ge 3 ]] ||
		{ print -u2 'usage: secret exec <PROJ> -- <cmd...>'; return 2 }
	shift 2
	( _secret_load $proj || exit; "$@" )
}

# Read from the Keychain and export. Runs automatically at the end of this file.
# With <PROJ>, export <PROJ>/<KEY> as <KEY> in this shell.
_secret_load() {
	local k v
	local -a missing
	if [[ -n $1 ]]; then
		[[ $1 != */* ]] || { print -u2 'usage: secret load [PROJ]'; return 2 }
		_secret_proj_keys $1 || return
		for k in $reply; do
			v="$(_secret_get $k)" || { print -u2 "secret: cannot read $k"; return 1 }
			export ${k#$1/}="$v"
		done
		return 0
	fi
	for k in $_SECRET_KEYS; do
		v="$(_secret_get $k)"
		if [[ -n $v ]]; then
			export $k="$v"
		else
			missing+=$k
		fi
	done
	(( $#missing )) && print -u2 "secrets: not stored -> $missing  (secret set <KEY>)"
	return 0
}

# Completion: subcommand -> key name / project name
_secret_complete() {
	if (( CURRENT == 2 )); then
		compadd get set rm ls load exec help
		return
	fi
	(( CURRENT == 3 )) || return
	case $words[2] in
	get|set|rm) compadd -- $_SECRET_KEYS ${${(M)${(f)"$(_secret_stored)"}:#*/*}} ;;
	ls|load|exec) compadd -- ${(u)${(M)${(f)"$(_secret_stored)"}:#*/*}%%/*} ;;
	esac
}
(( $+functions[compdef] )) && compdef _secret_complete secret

_secret_load
