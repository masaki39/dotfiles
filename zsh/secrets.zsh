# secrets.zsh
# API キー等を平文ファイルではなく macOS Keychain に置く。
# このファイルに値は入らないのでコミットしてよい。
#
#   secret set <KEY>   Keychain に登録・更新する (値は対話入力)
#   secret get <KEY>   Keychain から 1 つ取り出して標準出力へ (secret <KEY> でも可)
#   secret rm  <KEY>   Keychain から削除し、このシェルからも unset する
#   secret ls          Keychain に登録済みの鍵名を一覧する (値は出さない)
#   secret load        Keychain から読み直して export する
#   secret help        使い方を表示する
#
# 読み込み時に自動で export されるので、普段は何も叩かなくてよい。
# 鍵を増やすときは _SECRET_KEYS に名前を足す。

_SECRET_KEYS=(
	CZ_OPENAI_API_KEY
	OPENROUTER_API_KEY
	HF_TOKEN
)
_SECRET_PREFIX='dot:'

secret() {
	local cmd=$1
	(( $# )) && shift
	case $cmd in
	get)  _secret_get "$@" ;;
	set)  _secret_set "$@" ;;
	rm)   _secret_rm "$@" ;;
	ls)   _secret_ls ;;
	load) _secret_load ;;
	help|-h|--help) _secret_help ;;
	'')   _secret_help >&2; return 2 ;;
	*)    _secret_get "$cmd" ;;
	esac
}

_secret_help() {
	print -r -- 'usage: secret <command> [KEY]

  set  <KEY>   Keychain に登録・更新する (値は対話入力)
  get  <KEY>   Keychain から 1 つ取り出して標準出力へ (secret <KEY> でも可)
  rm   <KEY>   Keychain から削除し、このシェルからも unset する
  ls           Keychain に登録済みの鍵名を一覧する (値は出さない)
                 ? = _SECRET_KEYS に無い  ! = Keychain に未登録
  load         Keychain から読み直して export する
  help         このヘルプを表示する

起動時に _SECRET_KEYS の鍵が自動で export される。'
}

_secret_get() {
	[[ -n $1 ]] || { print -u2 'usage: secret get <KEY>'; return 2 }
	security find-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" -w 2>/dev/null
}

_secret_set() {
	[[ -n $1 ]] || { print -u2 'usage: secret set <KEY>'; return 2 }
	security add-generic-password -U -s "${_SECRET_PREFIX}$1" -a "$USER" -w && _secret_load
}

_secret_rm() {
	[[ -n $1 ]] || { print -u2 'usage: secret rm <KEY>'; return 2 }
	security delete-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" >/dev/null && unset $1
}

# Keychain 上の鍵名を一覧する (値は出さない)。
# _SECRET_KEYS との差分があれば印を付ける。
_secret_ls() {
	local k
	local -a stored
	stored=(${(f)"$(security dump-keychain 2>/dev/null |
		sed -n "s/^ *\"svce\"<blob>=\"${_SECRET_PREFIX}\(.*\)\"\$/\1/p" | sort -u)"})
	for k in $stored; do
		if (( ${_SECRET_KEYS[(Ie)$k]} )); then
			print -- "  $k"
		else
			print -- "? $k  (_SECRET_KEYS に無いので自動 export されない)"
		fi
	done
	for k in $_SECRET_KEYS; do
		(( ${stored[(Ie)$k]} )) || print -- "! $k  (Keychain に未登録)"
	done
}

# Keychain から読んで export する。末尾で自動実行。
_secret_load() {
	local k v
	local -a missing
	for k in $_SECRET_KEYS; do
		v="$(_secret_get $k)"
		if [[ -n $v ]]; then
			export $k="$v"
		else
			missing+=$k
		fi
	done
	(( $#missing )) && print -u2 "secrets: 未登録 -> $missing  (secret set <KEY>)"
	return 0
}

_secret_load
