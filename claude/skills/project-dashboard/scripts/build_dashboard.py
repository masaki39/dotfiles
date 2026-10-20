"""
プロジェクト進捗ダッシュボードの生成（project-dashboard スキル）。

カレントディレクトリ（または $CLAUDE_PROJECT_DIR / --root DIR）の dashboard/status.toml
（目標・タスク・決定事項）と、任意で登録した実験結果JSON・git の状態を集計し、
dashboard/index.html を書き出す。標準ライブラリのみ・Python 3.11+（tomllib）。

Usage:
  S=~/.claude/skills/project-dashboard/scripts/build_dashboard.py
  uv run --no-project --python '>=3.11' $S            # HTML生成
  uv run --no-project --python '>=3.11' $S --open     # HTML生成してブラウザで開く
  uv run --no-project --python '>=3.11' $S --summary  # テキスト要約のみ（SessionStartフック用）
"""

import glob
import html
import json
import os
import re
import statistics
import subprocess
import sys
import tomllib
from collections import defaultdict
from datetime import datetime

def _root():
    if "--root" in sys.argv:
        return sys.argv[sys.argv.index("--root") + 1]
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


REPO = os.path.abspath(_root())
STATUS_PATH = os.path.join(REPO, "dashboard", "status.toml")
HTML_PATH = os.path.join(REPO, "dashboard", "index.html")

STATUS_LABELS = {
    "doing": "進行中",
    "decide": "判断待ち",
    "blocked": "ブロック",
    "todo": "未着手",
    "done": "完了",
}
STATUS_ORDER = ["doing", "decide", "blocked", "todo", "done"]


# ---------------------------------------------------------------------------
# 集計
# ---------------------------------------------------------------------------
def _dig(d, dotted):
    for k in dotted.split("."):
        if not isinstance(d, dict) or k not in d:
            return None
        d = d[k]
    return d


def collect_experiment(exp):
    """結果ディレクトリの fold*_size*.json をサイズ別に集計する。"""
    out = {"name": exp["name"], "metric_label": exp.get("metric_label", exp["metric"]), "note": exp.get("note", ""),
           "expected": exp["expected_jobs"], "mounted": os.path.isdir(os.path.dirname(exp["dir"]))}
    if not out["mounted"]:
        return out
    by_size = defaultdict(list)
    files = sorted(glob.glob(os.path.join(exp["dir"], exp.get("glob", "fold*_size*.json"))))
    for f in files:
        # size別に集計（sizeを持たない結果はfold番号で並べる）
        m = re.search(r"size(\d+)", os.path.basename(f)) or re.search(r"fold(\d+)", os.path.basename(f))
        with open(f) as fp:
            v = _dig(json.load(fp), exp["metric"])
        if m and v is not None:
            by_size[int(m.group(1))].append(v)
    # 最大サイズは訓練プール数でcapされfoldごとに148/149等とずれるため、差が2以内のサイズは束ねる
    out["is_curve"] = "glob" not in exp  # size別の学習曲線か（Falseならfold別の結果）
    groups = []
    for size in sorted(by_size):
        if out["is_curve"] and groups and size - groups[-1][-1] <= 2:
            groups[-1].append(size)
        else:
            groups.append([size])
    out["done"] = len(files)
    out["rows"] = []
    for g in groups:
        vals = [v for size in g for v in by_size[size]]
        label = str(g[0]) if len(g) == 1 else f"{g[0]}–{g[-1]}"
        out["rows"].append((label, len(vals), statistics.mean(vals),
                            statistics.stdev(vals) if len(vals) > 1 else None, g[0]))
    out["updated"] = (
        datetime.fromtimestamp(max(os.path.getmtime(f) for f in files)).strftime("%m-%d %H:%M")
        if files else None
    )
    log = exp.get("log")
    if log and os.path.exists(log):
        out["log_updated"] = datetime.fromtimestamp(os.path.getmtime(log)).strftime("%m-%d %H:%M")
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
    target = f"（{g.get('target_label', '期限・提出先')}: {g['target']}）" if g.get("target") else ""
    lines = [f"[プロジェクトダッシュボード] 目標: {g['title']}{target}"]
    if g.get("glossary"):
        lines.append("用語:")
        lines += [f"  - {x}" for x in g["glossary"]]
    lines.append("次にやること:")
    lines += [f"  {i}. {a}" for i, a in enumerate(g.get("next_actions", []), 1)]
    for key in ("doing", "decide", "blocked"):
        items = [(m["name"], t) for m in st.get("milestones", []) for t in m["tasks"] if t["status"] == key]
        if items:
            lines.append(f"{STATUS_LABELS[key]}:")
            lines += [f"  - [{name}] {t['title']}" for name, t in items]
    if exps:
        lines.append("実験:")
    for e in exps:
        state = f"{e['done']}/{e['expected']} jobs" if e["mounted"] else "結果ディレクトリ未接続"
        lines.append(f"  - {e['name']}: {state}")
    lines.append("管理: dashboard/status.toml（作業の区切りごとに更新し、project-dashboard スキルの手順でHTMLを再生成）")
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
h2{font-size:13px;letter-spacing:.06em;color:var(--muted);font-weight:600;margin:32px 0 12px;text-transform:uppercase}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:18px}
.card h3{font-size:15px;margin:0 0 10px}
.grid2{display:grid;grid-template-columns:3fr 2fr;gap:16px}
.grid3{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(300px,100%),1fr));gap:16px}
@media (max-width:820px){.grid2{grid-template-columns:1fr}}
.next ol{margin:0;padding-left:22px}.next li{margin:8px 0;font-size:15px}
.next li::marker{color:var(--accent);font-weight:700}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(170px,100%),1fr));gap:12px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
.kpi .l{color:var(--muted);font-size:12px}.kpi .v{font-size:20px;font-weight:650;margin:2px 0;font-variant-numeric:tabular-nums;white-space:nowrap}
.kpi .n{color:var(--faint);font-size:12px}
.chip{display:inline-block;font-size:11px;font-weight:600;padding:2px 9px;border-radius:99px;
color:var(--c);border:1px solid var(--c);white-space:nowrap;line-height:1.5}
.task{display:flex;gap:10px;align-items:baseline;padding:8px 0;border-top:1px solid var(--line)}
.task:first-child{border-top:0}.task .t{font-weight:500}.task .note{color:var(--muted);font-size:12.5px}
.task.done .t{color:var(--muted);font-weight:400}
.bar{height:6px;background:var(--grid);border-radius:3px;overflow:hidden;margin:4px 0 12px}
.bar>div{height:100%;background:var(--done)}
.mhead{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.mhead .sub{color:var(--muted);font-size:12px;white-space:nowrap}
details summary{cursor:pointer;color:var(--muted);font-size:12.5px;margin-top:8px}
.exp .top{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.exp .sub{color:var(--muted);font-size:12px}
svg.lc{width:100%;height:auto;display:block;margin-top:8px;overflow:visible}
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


def _chip(status):
    return f'<span class="chip" style="--c:var(--{status})">{STATUS_LABELS[status]}</span>'


def _fmt(v):
    return f"{v:.3f}" if abs(v) < 1 else f"{v:.2f}"


def _curve_svg(e):
    """学習曲線（平均±SD帯）の小さな折れ線。1系列なので凡例なし、値はhoverと表で読む。"""
    rows = [r for r in e["rows"]]
    if len(rows) < 2:
        return ""
    W, H, L, R, T, B = 420, 180, 44, 12, 10, 28
    xs = [r[4] for r in rows]
    lo = [r[2] - (r[3] or 0) for r in rows]
    hi = [r[2] + (r[3] or 0) for r in rows]
    ymin, ymax = 0.0, max(hi) * 1.1
    X = lambda x: L + (x - min(xs)) / (max(xs) - min(xs)) * (W - L - R)
    Y = lambda y: T + (1 - (y - ymin) / (ymax - ymin)) * (H - T - B)
    grid = []
    for i in range(5):
        v = ymin + (ymax - ymin) * i / 4
        grid.append(f'<line x1="{L}" x2="{W-R}" y1="{Y(v):.1f}" y2="{Y(v):.1f}" stroke="var(--grid)"/>'
                    f'<text x="{L-6}" y="{Y(v)+4:.1f}" text-anchor="end">{_fmt(v)}</text>')
    xt = "".join(f'<text x="{X(x):.1f}" y="{H-8}" text-anchor="middle">{x}</text>' for x in xs)
    band = " ".join(f"{X(x):.1f},{Y(v):.1f}" for x, v in zip(xs, hi)) + " " + \
        " ".join(f"{X(x):.1f},{Y(v):.1f}" for x, v in reversed(list(zip(xs, lo))))
    line = " ".join(f"{X(r[4]):.1f},{Y(r[2]):.1f}" for r in rows)
    dots = "".join(
        f'<circle cx="{X(r[4]):.1f}" cy="{Y(r[2]):.1f}" r="4.5" fill="var(--accent)" stroke="var(--card)" stroke-width="2" '
        f'data-v="{_fmt(r[2])}{" ± " + _fmt(r[3]) if r[3] else ""}" data-l="{_e(r[0])}例 ・ {r[1]} folds"/>'
        for r in rows)
    return (f'<svg class="lc" viewBox="0 0 {W} {H}" role="img" aria-label="{_e(e["name"])} の学習曲線">'
            f'{"".join(grid)}{xt}<polygon points="{band}" fill="var(--accent-soft)"/>'
            f'<polyline points="{line}" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round"/>'
            f'<line class="hair" y1="{T}" y2="{H-B}" stroke="var(--faint)" stroke-dasharray="3 3" style="display:none"/>'
            f'{dots}<text x="{L}" y="{T-0}" dy="-2" style="display:none"></text></svg>'
            f'<div class="sub" style="margin-top:2px">横軸: 学習症例数 ・ 帯: ±SD（fold間）</div>')


def _exp_card(e):
    head = f'<div class="top"><h3>{_e(e["name"])}</h3>'
    if not e["mounted"]:
        return f'<div class="card exp">{head}</div><div class="sub">結果ディレクトリが見つからないため集計できません</div></div>'
    done = e.get("done", 0)
    state = "done" if done >= e["expected"] else ("doing" if done else "todo")
    head += f'<span class="chip" style="--c:var(--{state})">{done}/{e["expected"]}</span></div>'
    meta = e["metric_label"] + (f' ・ 最終更新 {e["updated"]}' if e.get("updated") else "")
    body = [head, f'<div class="sub">{_e(meta)}</div>']
    if e.get("is_curve") and done:
        body.append(_curve_svg(e))
    if e.get("is_curve"):
        table = ['<table><tr><th>学習症例数</th><th>folds</th><th>平均</th><th>SD</th></tr>']
        for label, n, mean, sd, _ in e["rows"]:
            table.append(f"<tr><td>{_e(label)}</td><td>{n}</td><td>{_fmt(mean)}</td><td>{_fmt(sd) if sd else '—'}</td></tr>")
    else:
        vals = [r[2] for r in e["rows"]]
        table = ['<table><tr><th>fold</th><th>値</th></tr>']
        table += [f"<tr><td>{_e(r[0])}</td><td>{_fmt(r[2])}</td></tr>" for r in e["rows"]]
        if len(vals) > 1:
            table.append(f"<tr><td><b>平均 ± SD</b></td><td><b>{_fmt(statistics.mean(vals))} ± "
                         f"{_fmt(statistics.stdev(vals))}</b></td></tr>")
    table.append("</table>")
    if e.get("note"):
        body.append(f'<div class="sub">{_e(e["note"])}</div>')
    if e.get("is_curve") and len(e["rows"]) > 1:
        body.append(f'<details><summary>表で見る</summary>{"".join(table)}</details>')
    elif done:
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
    target = (f"<span>{_e(g.get('target_label', '期限・提出先'))} <b>{_e(g['target'])}</b></span>"
              if g.get("target") else "")
    lead = f'<p class="lead">{_e(g["summary"])}</p>' if g.get("summary") else ""
    milestones = st.get("milestones", [])
    P = [f"""<!doctype html><html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{_e(g.get('short_title', 'プロジェクトダッシュボード'))}</title><style>{CSS}</style></head><body><main>
<header><h1>{_e(g['title'])}</h1>
<div class="meta">{target}<span>更新 {now}</span><span>branch {_e(git['branch'])}</span></div>
{lead}</header>"""]

    # 1. 次にやること ＋ 判断待ち・進行中
    hot = sorted([(m["name"], t) for m in milestones for t in m["tasks"]
                  if t["status"] in ("doing", "decide", "blocked")],
                 key=lambda x: STATUS_ORDER.index(x[1]["status"]))
    P.append('<h2>いまやること</h2><div class="grid2">')
    P.append('<div class="card next"><h3>次にやること</h3><ol>'
             + "".join(f"<li>{_e(a)}</li>" for a in g.get("next_actions", [])) + "</ol></div>")
    P.append('<div class="card"><h3>判断待ち・進行中</h3>'
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
    P.append('<h2>マイルストーン</h2><div class="grid3">')
    for m in milestones:
        n_done = sum(t["status"] == "done" for t in m["tasks"])
        pct = 100 * n_done / len(m["tasks"]) if m["tasks"] else 0
        open_ = [t for t in m["tasks"] if t["status"] != "done"]
        done = [t for t in m["tasks"] if t["status"] == "done"]
        P.append(f'<div class="card"><div class="mhead"><h3>{_e(m["name"])}</h3>'
                 f'<span class="sub">{n_done}/{len(m["tasks"])} 完了</span></div>'
                 f'<div class="bar"><div style="width:{pct:.0f}%"></div></div>')
        P.append("".join(_task(t) for t in sorted(open_, key=lambda t: STATUS_ORDER.index(t["status"]))))
        if done:
            P.append(f'<details {"open" if not open_ else ""}><summary>完了 {len(done)} 件</summary>'
                     + "".join(_task(t) for t in done) + "</details>")
        P.append("</div>")
    P.append("</div>")

    # 5. 参考情報
    P.append('<h2>参考</h2><div class="grid3">')
    if g.get("glossary"):
        P.append('<div class="card"><h3>用語</h3><ul class="plain">'
                 + "".join(f"<li>{_e(x)}</li>" for x in g["glossary"]) + "</ul></div>")
    if st.get("decisions"):
        P.append('<div class="card"><h3>決定事項</h3><ul class="plain">'
                 + "".join(f'<li><code>{_e(d["date"])}</code> {_e(d["text"])}</li>' for d in st["decisions"])
                 + "</ul></div>")
    P.append('<div class="card"><h3>最近のコミット</h3><table>'
             + "".join(f"<tr><td><code>{_e(h)}</code> {_e(s_)}</td><td><code>{_e(d)}</code></td></tr>"
                       for h, d, s_ in git["commits"]) + "</table>")
    if git["dirty"]:
        P.append(f'<details><summary>未コミットの変更 {len(git["dirty"])} 件</summary><ul class="plain">'
                 + "".join(f"<li><code>{_e(x)}</code></li>" for x in git["dirty"][:15]) + "</ul></details>")
    P.append("</div></div></main>")
    P.append(f"<script>{TIP_JS}</script></body></html>")
    return "\n".join(P)


def main():
    if not os.path.exists(STATUS_PATH):
        if "--summary" in sys.argv:
            return  # ダッシュボード未導入のプロジェクトでは何も出さない（グローバルフック用）
        sys.exit(f"見つかりません: {STATUS_PATH}（templates/status.toml をコピーして作成）")
    with open(STATUS_PATH, "rb") as f:
        st = tomllib.load(f)
    exps = [collect_experiment(e) for e in st.get("experiments", [])]

    if "--summary" in sys.argv:
        print(render_summary(st, exps))
        return

    with open(HTML_PATH, "w") as f:
        f.write(render_html(st, exps, collect_git()))
    print(f"生成: {HTML_PATH}")
    if "--open" in sys.argv:
        subprocess.run(["open", HTML_PATH])


if __name__ == "__main__":
    main()
