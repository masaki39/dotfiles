# secrets.zsh
# Keep API keys and the like in a dedicated macOS keychain instead of plain-text files.
# No values live in this file, so it is safe to commit.
#
# Two rules limit what a malicious process (e.g. an npm postinstall script) can steal:
#   - Nothing is exported at shell startup. A key exists only in the environment of the
#     command that needs it (`secret run`, `secret exec`, or a wrapper in _SECRET_WRAP).
#   - Keys live in their own keychain that locks after _SECRET_LOCK_AFTER seconds idle and
#     on sleep. While it is locked, reading a key asks for that keychain's password.
#
#   secret init        create the keychain (once per machine)
#   secret set <KEY>   add or update (interactive on a TTY, stdin otherwise)
#   secret get <KEY>   print one value (also: secret <KEY>)
#   secret rm  <KEY>   delete (<PROJ>/ deletes a project)
#   secret ls [PROJ]   list key names (never values); with PROJ, list that project's keys
#   secret run <KEY...> -- <cmd...>   run cmd with those keys exported
#   secret exec <PROJ> -- <cmd...>    run cmd with <PROJ>/-prefixed keys exported without the prefix
#   secret load <PROJ> export a project's keys into this shell (avoid; prefer exec)
#   secret lock | unlock
#   secret help        show usage
#
# To give a command its keys automatically, add `command "KEY ..."` to _SECRET_WRAP.
# Project-only keys are stored with `secret set <PROJ>/<KEY>` and passed with `secret exec`.

# command -> space-separated keys it receives. A wrapper function is defined for each.
typeset -gA _SECRET_WRAP=(
	czg 'CZ_OPENAI_API_KEY'
)
_SECRET_PREFIX='dot:'
_SECRET_KC=$HOME/Library/Keychains/dot-secrets.keychain-db
_SECRET_LOCK_AFTER=300

secret() {
	local cmd=$1
	(( $# )) && shift
	case $cmd in
	init)   _secret_init "$@" ;;
	get)    _secret_get "$@" ;;
	set)    _secret_set "$@" ;;
	rm)     _secret_rm "$@" ;;
	ls)     _secret_ls "$@" ;;
	run)    _secret_run "$@" ;;
	exec)   _secret_exec "$@" ;;
	load)   _secret_load "$@" ;;
	lock)   _secret_ready && security lock-keychain "$_SECRET_KC" ;;
	unlock) _secret_ready && security unlock-keychain "$_SECRET_KC" ;;
	help|-h|--help) _secret_help ;;
	'')     _secret_help >&2; return 2 ;;
	*)      _secret_get "$cmd" ;;
	esac
}

_secret_help() {
	print -r -- "usage: secret <command> [KEY]

  init         create the keychain (asks for a new password; use one you do not use elsewhere)
  set  <KEY>   add or update
                 reads a TTY interactively, otherwise stdin (printf %s \"\$v\" | secret set KEY)
  get  <KEY>   print one value (also: secret <KEY>)
  rm   <KEY>   delete
  rm   <PROJ>/ delete all keys of that project
  ls [PROJ]    list key names (never values)
                 no arg: global keys and project names  PROJ: keys of that project
                 ? = not used by any wrapper  ! = used by a wrapper but not stored
  run <KEY...> -- <cmd...>
               run cmd with those keys exported (only cmd and its children see them)
  exec <PROJ> -- <cmd...>
               run cmd with <PROJ>/<KEY> exported as <KEY>
  load <PROJ>  export <PROJ>/<KEY> as <KEY> in this shell (prefer exec)
  lock         lock the keychain now
  unlock       unlock it (asks for its password in the terminal; useful over ssh)
  help         show this help

The keychain locks after ${_SECRET_LOCK_AFTER}s idle and on sleep; reading a key while it is
locked asks for its password. Wrapped commands: ${(k)_SECRET_WRAP}"
}

_secret_ready() {
	[[ -f $_SECRET_KC ]] || { print -u2 'secret: keychain not created yet (run: secret init)'; return 1 }
}

# Create the keychain and keep it out of the search list.
_secret_init() {
	local -a list
	if [[ ! -f $_SECRET_KC ]]; then
		[[ -t 0 ]] || { print -u2 'secret init: run it in a terminal (it asks for a password)'; return 1 }
		print -u2 'secret: choose a password for the secrets keychain'
		# A bare name is created in ~/Library/Keychains as <name>-db
		security create-keychain "${_SECRET_KC:t:r}.keychain" || return
		[[ -f $_SECRET_KC ]] || { print -u2 "secret: $_SECRET_KC was not created"; return 1 }
	fi
	# -l: lock on sleep, -u -t: lock after that many idle seconds
	security set-keychain-settings -l -u -t $_SECRET_LOCK_AFTER "$_SECRET_KC" || return
	# create-keychain adds it to the search list; drop it so other apps never query it
	list=(${(Q)${${(f)"$(security list-keychains -d user)"}##[[:space:]]#}})
	list=(${list:#$_SECRET_KC})
	security list-keychains -d user -s $list || return
	print -u2 "secret: ready ($_SECRET_KC, locks after ${_SECRET_LOCK_AFTER}s idle)"
}

_secret_get() {
	[[ -n $1 ]] || { print -u2 'usage: secret get <KEY>'; return 2 }
	_secret_ready || return
	security find-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" -w "$_SECRET_KC" 2>/dev/null
}

# The value is read with hidden input on a TTY, otherwise from stdin (for agents).
# A value passed as an argument would show up in ps, so the command goes to security -i via stdin.
# (security add-generic-password -w is not used because its prompt truncates at 128 chars)
_secret_set() {
	[[ -n $1 && $1 != *[[:space:]\"\\]* ]] ||
		{ print -u2 'usage: secret set <KEY>  (value from stdin or interactive input)'; return 2 }
	_secret_ready || return
	local v
	if [[ -t 0 ]]; then
		read -rs "v?$1: " || return 1
		print -u2
	else
		v="$(cat)"
	fi
	[[ -n $v ]] || { print -u2 'secret: empty value'; return 1 }
	[[ $v != *$'\n'* ]] || { print -u2 'secret: value must not contain a newline'; return 1 }
	print -r -- "add-generic-password -U -s \"${_SECRET_PREFIX}$1\" -a \"$USER\" -w \"${${v//\\/\\\\}//\"/\\\"}\" \"$_SECRET_KC\"" |
		security -i >/dev/null
	# security -i returns 0 even on failure, so read the value back to verify
	[[ "$(_secret_get $1)" == "$v" ]] || { print -u2 "secret: failed to store $1"; return 1 }
}

_secret_rm() {
	[[ -n $1 ]] || { print -u2 'usage: secret rm <KEY> | <PROJ>/'; return 2 }
	_secret_ready || return
	# <PROJ>/ deletes every key of that project
	if [[ $1 == */ ]]; then
		local proj=${1%/} k
		[[ -n $proj && $proj != */* ]] || { print -u2 'usage: secret rm <PROJ>/'; return 2 }
		_secret_proj_keys $proj || return
		for k in $reply; do _secret_rm $k || return; done
		return 0
	fi
	security delete-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" "$_SECRET_KC" >/dev/null
}

# Print key names stored in the keychain (without the prefix), one per line.
_secret_stored() {
	security dump-keychain "$_SECRET_KC" 2>/dev/null |
		sed -n "s/^ *\"svce\"<blob>=\"${_SECRET_PREFIX}\(.*\)\"\$/\1/p" | sort -u
}

# Put the <PROJ>/-prefixed key names into reply. Error if there are none.
_secret_proj_keys() {
	reply=(${(M)${(f)"$(_secret_stored)"}:#$1/*})
	(( $#reply )) ||
		{ print -u2 "secret: no keys stored for $1/ (secret set $1/<KEY>)"; return 1 }
}

# List key names (never values).
# With no argument, show global keys and project names; with <PROJ>, that project's keys.
# Mark differences from _SECRET_WRAP.
_secret_ls() {
	local k p
	local -a stored projs pkeys wrapped
	_secret_ready || return
	if [[ -n $1 ]]; then
		[[ $1 != */* ]] || { print -u2 'usage: secret ls [PROJ]'; return 2 }
		_secret_proj_keys $1 || return
		for k in $reply; do print -- "  ${k#$1/}"; done
		return 0
	fi
	stored=(${(f)"$(_secret_stored)"})
	wrapped=(${(u)${=${(v)_SECRET_WRAP}}})
	for k in ${stored:#*/*}; do
		if (( ${wrapped[(Ie)$k]} )); then
			print -- "  $k"
		else
			print -- "? $k"
		fi
	done
	for k in $wrapped; do
		(( ${stored[(Ie)$k]} )) || print -- "! $k"
	done
	projs=(${(u)${(M)stored:#*/*}%%/*})
	for p in $projs; do
		pkeys=(${(M)stored:#$p/*})
		print -- "  $p/  ($#pkeys keys)"
	done
}

# Run cmd in a subshell with the given global keys exported. Nothing leaks into the caller.
_secret_run() {
	local -a keys
	while (( $# )) && [[ $1 != -- ]]; do keys+=$1; shift; done
	[[ $1 == -- && $# -ge 2 && $#keys -gt 0 && -z ${(M)keys:#*/*} ]] ||
		{ print -u2 'usage: secret run <KEY...> -- <cmd...>'; return 2 }
	shift
	(
		local k v
		for k in $keys; do
			v="$(_secret_get $k)" && [[ -n $v ]] ||
				{ print -u2 "secret: cannot read $k (secret set $k)"; exit 1 }
			export $k="$v"
		done
		"$@"
	)
}

# Run cmd in a subshell with <PROJ>/<KEY> exported as <KEY>.
_secret_exec() {
	local proj=$1
	[[ -n $proj && $proj != */* && $2 == -- && $# -ge 3 ]] ||
		{ print -u2 'usage: secret exec <PROJ> -- <cmd...>'; return 2 }
	shift 2
	( _secret_load $proj || exit; "$@" )
}

# Export <PROJ>/<KEY> as <KEY> in this shell.
_secret_load() {
	local k v
	[[ -n $1 && $1 != */* ]] || { print -u2 'usage: secret load <PROJ>'; return 2 }
	_secret_ready || return
	_secret_proj_keys $1 || return
	for k in $reply; do
		v="$(_secret_get $k)" || { print -u2 "secret: cannot read $k"; return 1 }
		export ${k#$1/}="$v"
	done
}

# Wrapper functions: `czg ...` becomes `secret run CZ_OPENAI_API_KEY -- command czg ...`
() {
	local c
	for c in ${(k)_SECRET_WRAP}; do
		functions[$c]="secret run ${_SECRET_WRAP[$c]} -- command $c \"\$@\""
	done
}

# Completion: subcommand -> key name / project name
_secret_complete() {
	if (( CURRENT == 2 )); then
		compadd init get set rm ls run exec load lock unlock help
		return
	fi
	case $words[2] in
	get|set|rm) (( CURRENT == 3 )) &&
		compadd -- ${(u)${=${(v)_SECRET_WRAP}}} ${${(M)${(f)"$(_secret_stored)"}:#*/*}} ;;
	run) [[ ${words[(I)--]} -eq 0 || ${words[(I)--]} -gt CURRENT ]] &&
		compadd -- ${(u)${=${(v)_SECRET_WRAP}}} ${${(f)"$(_secret_stored)"}:#*/*} ;;
	ls|load|exec) (( CURRENT == 3 )) &&
		compadd -- ${(u)${(M)${(f)"$(_secret_stored)"}:#*/*}%%/*} ;;
	esac
}
if (( $+functions[compdef] )); then compdef _secret_complete secret; fi
