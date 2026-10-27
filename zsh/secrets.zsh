# secrets.zsh
# API キー等を平文ファイルではなく macOS Keychain に置く。
# このファイルに値は入らないのでコミットしてよい。
#
#   secret set <KEY>   Keychain に登録・更新する (端末なら対話入力、パイプなら標準入力)
#   secret get <KEY>   Keychain から 1 つ取り出して標準出力へ (secret <KEY> でも可)
#   secret rm  <KEY>   Keychain から削除し、このシェルからも unset する (<PROJ>/ で一括)
#   secret ls [PROJ]   鍵名を一覧する (値は出さない)。PROJ を渡すとそのプロジェクトの鍵
#   secret load [PROJ] Keychain から読み直して export する。PROJ を渡すとそのプロジェクトの鍵
#   secret exec <PROJ> -- <cmd...>
#                      <PROJ>/ 付きの鍵を接頭辞を外して export し、cmd を実行する
#   secret help        使い方を表示する
#
# 読み込み時に自動で export されるので、普段は何も叩かなくてよい。
# 鍵を増やすときは _SECRET_KEYS に名前を足す。
# プロジェクト専用の鍵は `secret set <PROJ>/<KEY>` で登録し、
# _SECRET_KEYS には足さずに `secret exec <PROJ> -- cmd` で渡す。

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

  set  <KEY>   Keychain に登録・更新する
                 端末なら対話入力、パイプなら標準入力から読む (printf %s "$v" | secret set KEY)
  get  <KEY>   Keychain から 1 つ取り出して標準出力へ (secret <KEY> でも可)
  rm   <KEY>   Keychain から削除し、このシェルからも unset する
  rm   <PROJ>/ そのプロジェクトの鍵をすべて削除する
  ls [PROJ]    Keychain に登録済みの鍵名を一覧する (値は出さない)
                 引数なし: グローバルの鍵とプロジェクト名  PROJ: そのプロジェクトの鍵
                 ? = _SECRET_KEYS に無い  ! = Keychain に未登録
  load [PROJ]  Keychain から読み直して export する
                 PROJ: <PROJ>/<KEY> の鍵を <KEY> としてこのシェルに export
  exec <PROJ> -- <cmd...>
               <PROJ>/<KEY> の鍵を <KEY> として export し、cmd を実行する
  help         このヘルプを表示する

起動時に _SECRET_KEYS の鍵が自動で export される。
プロジェクト専用の鍵は `secret set <PROJ>/<KEY>` で登録する (自動 export されない)。'
}

_secret_get() {
	[[ -n $1 ]] || { print -u2 'usage: secret get <KEY>'; return 2 }
	security find-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" -w 2>/dev/null
}

# 値は端末なら伏せ字で対話入力、そうでなければ標準入力から読む (エージェント用)。
# 引数に値を載せると ps に見えるので、security -i に標準入力でコマンドを渡す。
# (security add-generic-password -w のプロンプトは 128 文字で切れるので使わない)
_secret_set() {
	[[ -n $1 && $1 != *[[:space:]\"\\]* ]] ||
		{ print -u2 'usage: secret set <KEY>  (値は標準入力 or 対話入力)'; return 2 }
	local v
	if [[ -t 0 ]]; then
		read -rs "v?$1: " || return 1
		print -u2
	else
		v="$(cat)"
	fi
	[[ -n $v ]] || { print -u2 'secret: 値が空'; return 1 }
	[[ $v != *$'\n'* ]] || { print -u2 'secret: 値に改行は入れられない'; return 1 }
	print -r -- "add-generic-password -U -s \"${_SECRET_PREFIX}$1\" -a \"$USER\" -w \"${${v//\\/\\\\}//\"/\\\"}\"" |
		security -i >/dev/null
	# security -i は失敗しても 0 を返すので読み戻して確かめる
	[[ "$(_secret_get $1)" == "$v" ]] || { print -u2 "secret: $1 を保存できなかった"; return 1 }
	[[ $1 == */* ]] || _secret_load
}

_secret_rm() {
	[[ -n $1 ]] || { print -u2 'usage: secret rm <KEY> | <PROJ>/'; return 2 }
	# <PROJ>/ ならそのプロジェクトの鍵をすべて消す
	if [[ $1 == */ ]]; then
		local proj=${1%/} k
		[[ -n $proj && $proj != */* ]] || { print -u2 'usage: secret rm <PROJ>/'; return 2 }
		_secret_proj_keys $proj || return
		for k in $reply; do _secret_rm $k || return; done
		return 0
	fi
	security delete-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" >/dev/null || return
	# プロジェクト専用の鍵 (PROJ/KEY) は export していないので unset しない
	[[ $1 == */* ]] || unset $1
}

# Keychain 上の鍵名 (接頭辞を除いたもの) を 1 行ずつ出す。
_secret_stored() {
	security dump-keychain 2>/dev/null |
		sed -n "s/^ *\"svce\"<blob>=\"${_SECRET_PREFIX}\(.*\)\"\$/\1/p" | sort -u
}

# <PROJ>/ の鍵名 (接頭辞付き) を reply に入れる。1 つも無ければエラー。
_secret_proj_keys() {
	reply=(${(M)${(f)"$(_secret_stored)"}:#$1/*})
	(( $#reply )) ||
		{ print -u2 "secret: $1/ の鍵が未登録 (secret set $1/<KEY>)"; return 1 }
}

# Keychain 上の鍵名を一覧する (値は出さない)。
# 引数なしならグローバルの鍵とプロジェクト名、<PROJ> を渡すとその鍵を出す。
# _SECRET_KEYS との差分があれば印を付ける。
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
			print -- "? $k  (_SECRET_KEYS に無いので自動 export されない)"
		fi
	done
	for k in $_SECRET_KEYS; do
		(( ${stored[(Ie)$k]} )) || print -- "! $k  (Keychain に未登録)"
	done
	projs=(${(u)${(M)stored:#*/*}%%/*})
	for p in $projs; do
		pkeys=(${(M)stored:#$p/*})
		print -- "  $p/  ($#pkeys 個, secret ls $p で一覧)"
	done
}

# <PROJ>/<KEY> の鍵を <KEY> として export したサブシェルで cmd を実行する。
# 呼び出し元のシェルには何も残らない。
_secret_exec() {
	local proj=$1
	[[ -n $proj && $proj != */* && $2 == -- && $# -ge 3 ]] ||
		{ print -u2 'usage: secret exec <PROJ> -- <cmd...>'; return 2 }
	shift 2
	( _secret_load $proj || exit; "$@" )
}

# Keychain から読んで export する。末尾で自動実行。
# <PROJ> を渡すと <PROJ>/<KEY> の鍵を <KEY> としてこのシェルに export する。
_secret_load() {
	local k v
	local -a missing
	if [[ -n $1 ]]; then
		[[ $1 != */* ]] || { print -u2 'usage: secret load [PROJ]'; return 2 }
		_secret_proj_keys $1 || return
		for k in $reply; do
			v="$(_secret_get $k)" || { print -u2 "secret: $k を読めない"; return 1 }
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
	(( $#missing )) && print -u2 "secrets: 未登録 -> $missing  (secret set <KEY>)"
	return 0
}

# 補完: サブコマンド → 鍵名 / プロジェクト名
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
