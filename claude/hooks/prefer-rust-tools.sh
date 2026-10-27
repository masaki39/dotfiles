#!/usr/bin/env bash
# PreToolUse(Bash): block find / grep in command position and steer to fd / rg.
# After a pipe (`... | grep foo`) is allowed. Quoted strings and heredoc bodies are ignored.
# On exit 2, stderr is returned to Claude.
exec python3 -c '
import json, os, re, shlex, shutil, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command") or ""
except Exception:
    sys.exit(0)

# Strip heredoc bodies (<<EOF / <<-EOF / <<"EOF" / <<'"'"'EOF'"'"')
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
    sys.exit(0)  # skip commands with unbalanced quotes

# Positions where a command can start (excluding after a pipe)
starters = {";", "&&", "||", "&", "(", "\n", "{", "then", "do", "else", "elif", "!"}
prefixes = {"sudo", "command", "time", "exec", "nohup", "env"}
at_start = True
for tok in tokens:
    if at_start:
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", tok) or tok in prefixes:
            continue
        name = os.path.basename(tok)
        if name == "find" and shutil.which("fd"):
            print("Use fd instead of find (e.g. fd -e md, fd -t f name dir).", file=sys.stderr)
            sys.exit(2)
        if name in ("grep", "egrep", "fgrep") and shutil.which("rg"):
            print("Use rg instead of grep (e.g. rg -n pattern, rg -l pattern -g \"*.ts\"). grep after a pipe is fine.", file=sys.stderr)
            sys.exit(2)
    at_start = tok in starters
'
