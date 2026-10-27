"""
プロジェクト進捗ダッシュボードの生成（dashboard スキル）。

プロジェクトルートの dashboard/status.toml（目標・タスク・決定事項）と、任意で登録した
実験結果JSON・git の状態を集計し、dashboard/index.html を書き出す（--summary ならテキスト要約）。
標準ライブラリのみ・Python 3.11+（tomllib）。実行方法は SKILL.md を参照。
"""

import argparse
import glob
import html
import json
import math
import os
import re
import statistics
import subprocess
import tomllib
from collections import defaultdict
from datetime import datetime

REPO = os.getcwd()  # main() で --root / $CLAUDE_PROJECT_DIR に置き換える

STATUS_LABELS = {
    "doing": "進行中",
    "decide": "判断待ち",
    "blocked": "ブロック",
    "todo": "未着手",
    "done": "完了",
}
STATUS_ORDER = ["doing", "decide", "blocked", "todo", "done"]
EXP_REQUIRED = ("name", "dir", "expected_jobs", "metric")


# ---------------------------------------------------------------------------
# 読み込み・検証
# ---------------------------------------------------------------------------
def load_status(path):
    """status.toml を読み、既定値を埋めて検証する。問題があれば ValueError。"""
    with open(path, "rb") as f:
        st = tomllib.load(f)
    g = st.get("goal")
    if not isinstance(g, dict) or not g.get("title"):
        raise ValueError("[goal].title がありません")
    g.setdefault("short_title", "プロジェクトダッシュボード")
    g.setdefault("target_label", "期限・提出先")
    for m in st.get("milestones", []):
        m.setdefault("name", "（無名）")
        m.setdefault("tasks", [])
        _require(m["tasks"], f"{m['name']} の tasks", ("title",))
        for t in m["tasks"]:
            if t.get("status") not in STATUS_LABELS:
                raise ValueError(f"不正な status: {m['name']}/{t['title']} = {t.get('status')!r}"
                                 f"（{' / '.join(STATUS_ORDER)}）")
    _require(st.get("results", []), "[[results]]", ("label", "value"))
    _require(st.get("decisions", []), "[[decisions]]", ("date", "text"))
    _require(st.get("experiments", []), "[[experiments]]", EXP_REQUIRED)
    for e in st.get("experiments", []):
        if not isinstance(e["expected_jobs"], int) or isinstance(e["expected_jobs"], bool):
            raise ValueError(f"[[experiments]] {e['name']} の expected_jobs は整数にしてください: {e['expected_jobs']!r}")
    return st


def _require(items, where, keys):
    for i, x in enumerate(items, 1):
        missing = [k for k in keys if k not in x]
        if missing:
            raise ValueError(f"{where} の {i} 件目に必須キーがありません: {', '.join(missing)}")


# ---------------------------------------------------------------------------
# 集計
# ---------------------------------------------------------------------------
def _dig(d, dotted):
    for k in dotted.split("."):
        if not isinstance(d, dict) or k not in d:
            return None
        d = d[k]
    return d


def _is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _sd(vals):
    return statistics.stdev(vals) if len(vals) > 1 else None


def collect_experiment(exp):
    """結果ディレクトリのJSONを、学習曲線ならサイズ別・それ以外は fold 別に集計する。"""
    d = os.path.normpath(os.path.join(REPO, os.path.expanduser(exp["dir"])))
    is_curve = "glob" not in exp  # size別の学習曲線か（Falseならfold別の結果）
    out = {"name": exp["name"], "metric_label": exp.get("metric_label", exp["metric"]),
           "note": exp.get("note", ""), "expected": exp["expected_jobs"], "is_curve": is_curve,
           "x_label": exp.get("x_label", "サイズ"), "group_label": exp.get("group_label", "fold"),
           "mounted": os.path.isdir(os.path.dirname(d)), "done": 0, "invalid": 0, "rows": []}
    if not out["mounted"]:
        return out
    files = sorted(glob.glob(os.path.join(d, exp.get("glob", "fold*_size*.json"))))
    key_re = r"size(\d+)" if is_curve else r"fold(\d+)"
    by_key = defaultdict(list)  # キー（size か fold 番号）-> [(fold, 値)]
    for f in files:
        name = os.path.basename(f)
        m = re.search(key_re, name)
        try:
            with open(f, encoding="utf-8") as fp:
                v = _dig(json.load(fp), exp["metric"])
        except (OSError, ValueError):  # 実行中のジョブが書きかけのJSONなど
            v = None
        if not m or not _is_num(v):
            out["invalid"] += 1
            continue
        fold = re.search(r"fold(\d+)", name)
        by_key[int(m.group(1))].append((fold.group(1) if fold else name, float(v)))
        out["done"] += 1

    # 最大サイズは fold ごとに上限が少しずれることがあるため、差が2以内で fold が重ならないサイズは束ねる
    groups = []
    for key in sorted(by_key):
        folds = {fd for fd, _ in by_key[key]}
        if (is_curve and groups and key - groups[-1][0] <= 2
                and not folds & {fd for k in groups[-1] for fd, _ in by_key[k]}):
            groups[-1].append(key)
        else:
            groups.append([key])
    for g in groups:
        vals = [v for k in g for _, v in by_key[k]]
        out["rows"].append({"label": str(g[0]) if len(g) == 1 else f"{g[0]}–{g[-1]}", "x": g[0],
                            "n": len(vals), "mean": statistics.mean(vals), "sd": _sd(vals)})
    if not is_curve and len(out["rows"]) > 1:
        means = [r["mean"] for r in out["rows"]]
        out["summary"] = (statistics.mean(means), _sd(means))
    if files:
        out["updated"] = datetime.fromtimestamp(max(os.path.getmtime(f) for f in files)).strftime("%m-%d %H:%M")
    return out


def _git(*args):
    try:
        return subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True,
                              timeout=10).stdout.strip()
    except Exception:
        return ""


def collect_git():
    log = _git("log", "-8", "--date=short", "--format=%h\t%ad\t%s")
    return {
        "branch": _git("branch", "--show-current"),
        "commits": [line.split("\t", 2) for line in log.splitlines() if line],
        "dirty": [line for line in _git("status", "--short").splitlines() if line],
    }


# ---------------------------------------------------------------------------
# テキスト要約（SessionStartフックで会話コンテキストに入る）
# ---------------------------------------------------------------------------
def render_summary(st, exps):
    g = st["goal"]
    target = f"（{g['target_label']}: {g['target']}）" if g.get("target") else ""
    lines = [f"[{g['short_title']}] 目標: {g['title']}{target}"]
    if g.get("glossary"):
        lines.append("用語:")
        lines += [f"  - {x}" for x in g["glossary"]]
    if g.get("next_actions"):
        lines.append("次にやること:")
        lines += [f"  {i}. {a}" for i, a in enumerate(g["next_actions"], 1)]
    for key in ("doing", "decide", "blocked"):
        items = [(m["name"], t) for m in st.get("milestones", []) for t in m["tasks"] if t["status"] == key]
        if items:
            lines.append(f"{STATUS_LABELS[key]}:")
            lines += [f"  - [{name}] {t['title']}" for name, t in items]
    if exps:
        lines.append("実験:")
    for e in exps:
        state = f"{e['done']}/{e['expected']} jobs" if e["mounted"] else "結果ディレクトリ未接続"
        if e["invalid"]:
            state += f"（読めない・値なし {e['invalid']} 件）"
        lines.append(f"  - {e['name']}: {state}")
    lines.append("管理: dashboard/status.toml（作業の区切りごとに更新し、dashboard スキルの手順でHTMLを再生成）")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------
CSS = """
:root{color-scheme:light;--bg:#f4f4f1;--card:#fcfcfb;--fg:#0b0b0b;--muted:#52514e;--faint:#8a8984;
--line:#e4e3de;--grid:#ecebe6;--accent:#2a78d6;--accent-soft:rgba(42,120,214,.14);
--doing:#2a78d6;--decide:#b86e00;--blocked:#c93b3b;--todo:#8a8984;--done:#1e8a4c}
@media (prefers-color-scheme:dark){:root:where(:not([data-theme="light"])){color-scheme:dark;--bg:#111110;
--card:#1a1a19;--fg:#fff;--muted:#c3c2b7;--faint:#8f8e86;--line:#2e2e2b;--grid:#262624;--accent:#3987e5;
--accent-soft:rgba(57,135,229,.2);--doing:#3987e5;--decide:#e0a13a;--blocked:#e66767;--todo:#8f8e86;--done:#3dbb74}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);overflow-wrap:anywhere;font:14px/1.6 -apple-system,"Hiragino Sans","Noto Sans JP",sans-serif}
main{max-width:1180px;margin:0 auto;padding:28px 16px 64px}
header h1{font-size:22px;line-height:1.35;margin:0 0 6px}
.meta{color:var(--muted);font-size:13px;display:flex;gap:14px;flex-wrap:wrap}
.lead{margin:10px 0 0;color:var(--muted);max-width:860px}
h2{font-size:13px;letter-spacing:.02em;color:var(--muted);font-weight:600;margin:32px 0 12px}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:18px}
.card h3{font-size:15px;margin:0 0 10px}
.grid2{display:grid;grid-template-columns:3fr 2fr;gap:16px}
.grid3{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(300px,100%),1fr));gap:16px}
@media (max-width:820px){.grid2{grid-template-columns:1fr}}
.next ol{margin:0;padding-left:22px}.next li{margin:8px 0;font-size:15px}
.next li::marker{color:var(--accent);font-weight:700}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(170px,100%),1fr));gap:12px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
.kpi .l{color:var(--muted);font-size:12px}.kpi .v{font-size:20px;font-weight:650;margin:2px 0;font-variant-numeric:tabular-nums}
.kpi .n{color:var(--faint);font-size:12px}
.chip{display:inline-block;min-width:4.5em;text-align:center;font-size:11px;font-weight:600;padding:2px 9px;
border-radius:99px;color:var(--c);border:1px solid var(--c);white-space:nowrap;line-height:1.5}
.note{color:var(--muted);font-size:12.5px}
.task{display:flex;gap:10px;align-items:baseline;padding:8px 0;border-top:1px solid var(--line)}
.task:first-child{border-top:0}.task .t{font-weight:500}
.task.done .t{color:var(--muted);font-weight:400}
.bar{height:6px;background:var(--grid);border-radius:3px;overflow:hidden;margin:4px 0 12px}
.bar>div{height:100%;background:var(--done)}
.mhead{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.mhead .sub{color:var(--muted);font-size:12px;white-space:nowrap}
details summary{cursor:pointer;color:var(--muted);font-size:12.5px;margin-top:8px}
.exp .top{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.exp .sub{color:var(--muted);font-size:12px}
svg.lc{width:100%;max-width:560px;height:auto;display:block;margin-top:8px;overflow:visible}
svg.lc text{fill:var(--muted);font-size:11px;font-variant-numeric:tabular-nums}
.tip{position:fixed;pointer-events:none;background:var(--card);border:1px solid var(--line);border-radius:8px;
padding:6px 10px;font-size:12px;box-shadow:0 4px 14px rgba(0,0,0,.12);display:none;z-index:9}
.tip b{font-size:14px}
table{border-collapse:collapse;width:100%;font-variant-numeric:tabular-nums;font-size:13px}
td,th{padding:4px 8px;border-bottom:1px solid var(--line);text-align:right}
th:first-child,td:first-child{text-align:left}th{color:var(--muted);font-weight:500;font-size:12px}
ul.plain{margin:0;padding-left:18px}ul.plain li{margin:6px 0}
code{font-size:12px;color:var(--muted)}
"""

TIP_JS = """
const tip=document.createElement('div');tip.className='tip';document.body.appendChild(tip);
document.querySelectorAll('svg.lc').forEach(svg=>{
  const pts=[...svg.querySelectorAll('[data-v]')];const hair=svg.querySelector('.hair');
  const show=e=>{const r=svg.getBoundingClientRect();const sx=svg.viewBox.baseVal.width/r.width;
    const x=(e.clientX-r.left)*sx;let best=pts[0],d=1e9;
    pts.forEach(p=>{const dd=Math.abs(+p.getAttribute('cx')-x);if(dd<d){d=dd;best=p}});
    hair.setAttribute('x1',best.getAttribute('cx'));hair.setAttribute('x2',best.getAttribute('cx'));hair.style.display='';
    tip.replaceChildren();const b=document.createElement('b');b.textContent=best.dataset.v;tip.append(b,
      document.createElement('br'),document.createTextNode(best.dataset.l));
    tip.style.display='block';tip.style.left=(e.clientX+14)+'px';tip.style.top=(e.clientY-10)+'px'};
  svg.addEventListener('pointermove',show);
  svg.addEventListener('pointerleave',()=>{tip.style.display='none';hair.style.display='none'});
});
"""


def _e(s):
    return html.escape(str(s))


def _chip(status, text=None):
    return f'<span class="chip" style="--c:var(--{status})">{_e(text or STATUS_LABELS[status])}</span>'


def _fmt(v, ref=None):
    """ref を渡すと ref と同じ桁数にする（平均 ± SD の桁を揃える用）。"""
    return f"{v:.3f}" if abs(v if ref is None else ref) < 1 else f"{v:.2f}"


def _ticks(lo, hi, n=4):
    """[lo, hi] を覆う 1-2-5 刻みのきりのいい目盛りと、表示桁数を返す。"""
    if hi == lo:
        pad = abs(lo) * 0.1 or 1
        lo, hi = lo - pad, hi + pad
    raw = (hi - lo) / n
    mag = 10 ** math.floor(math.log10(raw))
    step = next(m * mag for m in (1, 2, 5, 10) if m * mag >= raw)
    start = math.floor(lo / step + 1e-9)
    ticks = [i * step for i in range(start, math.ceil(hi / step - 1e-9) + 1)]
    return ticks, max(0, -math.floor(math.log10(step) + 1e-9))


def _curve_svg(e):
    """学習曲線（平均±SD帯）の小さな折れ線。1系列なので凡例なし、値はhoverと表で読む。"""
    rows = e["rows"]
    if len(rows) < 2:
        return ""
    W, H, L, R, T, B = 420, 180, 44, 12, 10, 28
    xs = [r["x"] for r in rows]
    lo = [r["mean"] - (r["sd"] or 0) for r in rows]
    hi = [r["mean"] + (r["sd"] or 0) for r in rows]
    ticks, dec = _ticks(min(lo), max(hi))
    ymin, ymax = ticks[0], ticks[-1]
    X = lambda x: L + (x - xs[0]) / (xs[-1] - xs[0]) * (W - L - R)
    Y = lambda y: T + (1 - (y - ymin) / (ymax - ymin)) * (H - T - B)
    grid = "".join(f'<line x1="{L}" x2="{W-R}" y1="{Y(v):.1f}" y2="{Y(v):.1f}" stroke="var(--grid)"/>'
                   f'<text x="{L-6}" y="{Y(v)+4:.1f}" text-anchor="end">{v:.{dec}f}</text>' for v in ticks)
    xt, last = [], -1e9
    for x in xs:  # 詰まったラベルは間引く（値はhoverと表で読める）
        if X(x) - last >= 28:
            xt.append(f'<text x="{X(x):.1f}" y="{H-8}" text-anchor="middle">{x}</text>')
            last = X(x)
    xt = "".join(xt)
    band = " ".join(f"{X(x):.1f},{Y(v):.1f}" for x, v in [*zip(xs, hi), *reversed(list(zip(xs, lo)))])
    line = " ".join(f"{X(r['x']):.1f},{Y(r['mean']):.1f}" for r in rows)
    dots = "".join(
        f'<circle cx="{X(r["x"]):.1f}" cy="{Y(r["mean"]):.1f}" r="4.5" fill="var(--accent)" stroke="var(--card)" '
        f'stroke-width="2" data-v="{_fmt(r["mean"])}{" ± " + _fmt(r["sd"], r["mean"]) if r["sd"] is not None else ""}" '
        f'data-l="{_e(e["x_label"])} {_e(r["label"])} ・ n={r["n"]}"/>'
        for r in rows)
    return (f'<svg class="lc" viewBox="0 0 {W} {H}" role="img" aria-label="{_e(e["name"])} の学習曲線">'
            f'{grid}{xt}<polygon points="{band}" fill="var(--accent-soft)"/>'
            f'<polyline points="{line}" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round"/>'
            f'<line class="hair" y1="{T}" y2="{H-B}" stroke="var(--faint)" stroke-dasharray="3 3" style="display:none"/>'
            f'{dots}</svg>'
            f'<div class="sub" style="margin-top:2px">横軸: {_e(e["x_label"])} ・ 帯: ±SD（{_e(e["group_label"])}間）</div>')


def _exp_card(e):
    head = f'<div class="top"><h3>{_e(e["name"])}</h3>'
    if not e["mounted"]:
        return f'<div class="card exp">{head}</div><div class="sub">結果ディレクトリが見つからないため集計できません</div></div>'
    done, expected = e["done"], e["expected"]
    # 予定より多いのは glob の当てはまり過ぎなので警告色にする
    state = "blocked" if done > expected else "done" if done == expected else "doing" if done else "todo"
    head += _chip(state, f"{done}/{expected}") + "</div>"
    meta = e["metric_label"] + (f' ・ 最終更新 {e["updated"]}' if e.get("updated") else "")
    body = [head, f'<div class="sub">{_e(meta)}</div>']
    if e["invalid"]:
        body.append(f'<div class="sub" style="color:var(--blocked)">読めない・値なしのファイル {e["invalid"]} 件</div>')
    if e["is_curve"]:
        body.append(_curve_svg(e))
        table = [f'<table><tr><th>{_e(e["x_label"])}</th><th>n</th><th>平均</th><th>SD</th></tr>']
        table += [f'<tr><td>{_e(r["label"])}</td><td>{r["n"]}</td><td>{_fmt(r["mean"])}</td>'
                  f'<td>{_fmt(r["sd"], r["mean"]) if r["sd"] is not None else "—"}</td></tr>' for r in e["rows"]]
    else:
        table = [f'<table><tr><th>{_e(e["group_label"])}</th><th>値</th></tr>']
        table += [f'<tr><td>{_e(r["label"])}</td><td>{_fmt(r["mean"])}</td></tr>' for r in e["rows"]]
        if e.get("summary"):
            mean, sd = e["summary"]
            table.append(f"<tr><td><b>平均 ± SD</b></td><td><b>{_fmt(mean)} ± {_fmt(sd, mean)}</b></td></tr>")
    table.append("</table>")
    if e.get("note"):
        body.append(f'<div class="sub">{_e(e["note"])}</div>')
    if e["is_curve"] and len(e["rows"]) > 1:
        body.append(f'<details><summary>表で見る</summary>{"".join(table)}</details>')
    elif e["rows"]:
        body.append("".join(table))
    return f'<div class="card exp">{"".join(body)}</div>'


def _task(t, name=None):
    note = t.get("note", "")
    if name:
        note = name + (" ・ " + note if note else "")
    note_html = f'<div class="note">{_e(note)}</div>' if note else ""
    return (f'<div class="task {t["status"]}">{_chip(t["status"])}'
            f'<div><div class="t">{_e(t["title"])}</div>{note_html}</div></div>')


def render_html(st, exps, git):
    g = st["goal"]
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    target = f"<span>{_e(g['target_label'])} <b>{_e(g['target'])}</b></span>" if g.get("target") else ""
    branch = f"<span>branch {_e(git['branch'])}</span>" if git["branch"] else ""
    lead = f'<p class="lead">{_e(g["summary"])}</p>' if g.get("summary") else ""
    milestones = st.get("milestones", [])
    P = [f"""<!doctype html><html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{_e(g['short_title'])}</title><style>{CSS}</style></head><body><main>
<header><h1>{_e(g['title'])}</h1>
<div class="meta">{target}<span>更新 {now}</span>{branch}</div>
{lead}</header>"""]

    # 1. 次にやること ＋ 動いているタスク
    hot = sorted([(m["name"], t) for m in milestones for t in m["tasks"]
                  if t["status"] in ("doing", "decide", "blocked")],
                 key=lambda x: STATUS_ORDER.index(x[1]["status"]))
    P.append('<h2>現在地</h2><div class="grid2">')
    actions = "".join(f"<li>{_e(a)}</li>" for a in g.get("next_actions", []))
    P.append('<div class="card next"><h3>次にやること</h3>'
             + (f"<ol>{actions}</ol>" if actions else '<div class="note">なし</div>') + "</div>")
    P.append('<div class="card"><h3>進行中・判断待ち・ブロック</h3>'
             + ("".join(_task(t, name) for name, t in hot) or '<div class="note">なし</div>') + "</div></div>")

    # 2. 主要数値
    if st.get("results"):
        P.append('<h2>主要結果</h2><div class="kpis">')
        for r in st["results"]:
            P.append(f'<div class="kpi"><div class="l">{_e(r["label"])}</div><div class="v">{_e(r["value"])}</div>'
                     f'<div class="n">{_e(r.get("note", ""))}</div></div>')
        P.append("</div>")

    # 3. 実験
    if exps:
        P.append('<h2>実験</h2><div class="grid3">' + "".join(_exp_card(e) for e in exps) + "</div>")

    # 4. マイルストーン（未完了を上に、完了は折りたたみ）
    if milestones:
        P.append('<h2>マイルストーン</h2><div class="grid3">')
    for m in milestones:
        tasks = m["tasks"]
        open_ = sorted((t for t in tasks if t["status"] != "done"), key=lambda t: STATUS_ORDER.index(t["status"]))
        done = [t for t in tasks if t["status"] == "done"]
        pct = 100 * len(done) / len(tasks) if tasks else 0
        P.append(f'<div class="card"><div class="mhead"><h3>{_e(m["name"])}</h3>'
                 f'<span class="sub">{len(done)}/{len(tasks)} 完了</span></div>'
                 f'<div class="bar"><div style="width:{pct:.0f}%"></div></div>')
        P.append("".join(_task(t) for t in open_))
        if done:
            P.append(f'<details {"open" if not open_ else ""}><summary>完了 {len(done)} 件</summary>'
                     + "".join(_task(t) for t in done) + "</details>")
        P.append("</div>")
    if milestones:
        P.append("</div>")

    # 5. 参考情報（中身のあるカードだけ）
    ref = []
    if g.get("glossary"):
        ref.append('<div class="card"><h3>用語</h3><ul class="plain">'
                   + "".join(f"<li>{_e(x)}</li>" for x in g["glossary"]) + "</ul></div>")
    if st.get("decisions"):
        ref.append('<div class="card"><h3>決定事項</h3><ul class="plain">'
                   + "".join(f'<li><code>{_e(d["date"])}</code> {_e(d["text"])}</li>' for d in st["decisions"])
                   + "</ul></div>")
    if git["commits"] or git["dirty"]:
        card = ['<div class="card"><h3>最近のコミット</h3><table>'
                + "".join(f"<tr><td><code>{_e(h)}</code> {_e(s_)}</td><td><code>{_e(d)}</code></td></tr>"
                          for h, d, s_ in git["commits"]) + "</table>"]
        if git["dirty"]:
            card.append(f'<details><summary>未コミットの変更 {len(git["dirty"])} 件</summary><ul class="plain">'
                        + "".join(f"<li><code>{_e(x)}</code></li>" for x in git["dirty"][:15]) + "</ul></details>")
        ref.append("".join(card) + "</div>")
    if ref:
        P.append('<h2>参考</h2><div class="grid3">' + "".join(ref) + "</div>")
    P.append(f"</main><script>{TIP_JS}</script></body></html>")
    return "\n".join(P)


def main():
    global REPO
    ap = argparse.ArgumentParser(description="dashboard/status.toml から HTML ダッシュボードを生成する")
    ap.add_argument("--root", help="プロジェクトルート（既定: $CLAUDE_PROJECT_DIR かカレントディレクトリ）")
    ap.add_argument("--open", action="store_true", help="生成後にブラウザで開く")
    ap.add_argument("--summary", action="store_true", help="テキスト要約だけを出力する（SessionStartフック用）")
    args = ap.parse_args()
    REPO = os.path.abspath(args.root or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    status_path = os.path.join(REPO, "dashboard", "status.toml")
    html_path = os.path.join(REPO, "dashboard", "index.html")

    if not os.path.exists(status_path):
        if args.summary:
            return  # ダッシュボード未導入のプロジェクトでは何も出さない（グローバルフック用）
        raise SystemExit(f"見つかりません: {status_path}（templates/status.toml をコピーして作成）")
    try:
        st = load_status(status_path)
        exps = [collect_experiment(e) for e in st.get("experiments", [])]
        if args.summary:
            print(render_summary(st, exps))
            return
    except Exception as ex:
        msg = f"[dashboard] status.toml の読み込みに失敗: {type(ex).__name__}: {ex}"
        if args.summary:
            print(msg)  # フックは stderr を捨てるので、会話に入るよう stdout に出す
            return
        raise SystemExit(msg)

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(render_html(st, exps, collect_git()))
    print(f"生成: {html_path}")
    if args.open:
        subprocess.run(["open", html_path])


if __name__ == "__main__":
    main()
