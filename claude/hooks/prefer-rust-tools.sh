#!/usr/bin/env bash
# PreToolUse(Bash): コマンド先頭の find / grep をブロックし fd / rg を使わせる。
# パイプ後 (`... | grep foo`) は対象外。exit 2 の stderr が Claude に返る。
cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# && || ; 改行 で区切った各セグメントの先頭語だけを見る (単独の | では区切らない)
segments=$(printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;)/\n/g')
while IFS= read -r seg; do
  # 先頭の空白・( ・環境変数代入・sudo/command/time を除去
  seg=$(printf '%s' "$seg" | sed -E 's/^[[:space:]({]+//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*//; s/^(sudo|command|time)[[:space:]]+//')
  first=${seg%%[[:space:]]*}
  case "$first" in
    find)
      command -v fd >/dev/null || continue
      echo "find ではなく fd を使ってください (例: fd -e md, fd -t f name dir)。" >&2
      exit 2 ;;
    grep|egrep|fgrep)
      command -v rg >/dev/null || continue
      echo "grep ではなく rg を使ってください (例: rg -n pattern, rg -l pattern -g '*.ts')。パイプ後の grep は可。" >&2
      exit 2 ;;
  esac
done <<< "$segments"
exit 0
