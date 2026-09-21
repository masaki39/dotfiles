# secrets.zsh
# API キー等を平文ファイルではなく macOS Keychain に置く。
# このファイルに値は入らないのでコミットしてよい。
#
#   secret-set <KEY>   Keychain に登録・更新する (値は対話入力)
#   secret     <KEY>   Keychain から 1 つ取り出して標準出力へ
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
	[[ -n $1 ]] || { print -u2 'usage: secret <KEY>'; return 2 }
	security find-generic-password -s "${_SECRET_PREFIX}$1" -a "$USER" -w 2>/dev/null
}

secret-set() {
	[[ -n $1 ]] || { print -u2 'usage: secret-set <KEY>'; return 2 }
	security add-generic-password -U -s "${_SECRET_PREFIX}$1" -a "$USER" -w && loadsecrets
}

# Keychain から読んで export する。末尾で自動実行。
# secret-set の後にこのシェルへ反映したいときは手で叩いてもよい。
loadsecrets() {
	local k v
	local -a missing
	for k in $_SECRET_KEYS; do
		v="$(secret $k)"
		if [[ -n $v ]]; then
			export $k="$v"
		else
			missing+=$k
		fi
	done
	(( $#missing )) && print -u2 "secrets: 未登録 -> $missing  (secret-set <KEY>)"
	return 0
}

loadsecrets
