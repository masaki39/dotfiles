#!/usr/bin/env bash
# PreToolUse(Bash): コマンド位置の find / grep をブロックし fd / rg を使わせる。
# パイプ後 (`... | grep foo`) は対象外。クォート内やヒアドキュメント本文は見ない。
# exit 2 の stderr が Claude に返る。
exec python3 -c '
import json, os, re, shlex, shutil, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command") or ""
except Exception:
    sys.exit(0)

# ヒアドキュメント本文を落とす (<<EOF / <<-EOF / <<"EOF" / <<'"'"'EOF'"'"')
lines, out, end = cmd.split("\n"), [], None
for line in lines:
    if end is not None:
        if line.strip() == end:
            end = None
        continue
    out.append(line)
    m = re.search(r"<<-?\s*[\"\x27]?([A-Za-z_][A-Za-z0-9_]*)[\"\x27]?", line)
    if m:
        end = m.group(1)
cmd = "\n".join(out)

try:
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace = " \t"
    tokens = list(lex)
except ValueError:
    sys.exit(0)  # クォートの対応が取れないものは判定しない

# コマンドの先頭になりうる位置 (パイプの後は除く)
starters = {";", "&&", "||", "&", "(", "\n", "{", "then", "do", "else", "elif", "!"}
prefixes = {"sudo", "command", "time", "exec", "nohup", "env"}
at_start = True
for tok in tokens:
    if at_start:
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", tok) or tok in prefixes:
            continue
        name = os.path.basename(tok)
        if name == "find" and shutil.which("fd"):
            print("find ではなく fd を使ってください (例: fd -e md, fd -t f name dir)。", file=sys.stderr)
            sys.exit(2)
        if name in ("grep", "egrep", "fgrep") and shutil.which("rg"):
            print("grep ではなく rg を使ってください (例: rg -n pattern, rg -l pattern -g \"*.ts\")。パイプ後の grep は可。", file=sys.stderr)
            sys.exit(2)
    at_start = tok in starters
'
