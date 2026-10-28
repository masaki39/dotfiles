#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["textual"]
# ///
"""Live viewer for the maji flow state of a herdr workspace.

The commander reports its state as workspace metadata (`--source maji`):
  phase=<investigate|decide|work|review|verify|report|done>  loop=<NG count>
  worker=<pane>  reviewer=<pane>  investigators=<pane>,<pane>,...

State comes from `herdr api snapshot`; refreshes are triggered by
`events.subscribe` on the herdr socket, falling back to 1s polling.

Usage: uv run --script viewer.py [--workspace ID] [--once] [--demo]
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

from rich.text import Text

PHASES = ["investigate", "decide", "work", "review", "verify", "report", "done"]
ROLE_PHASE = {"investigators": "investigate", "worker": "work", "reviewer": "review"}
# Palette (truecolor): cyan = live flow, teal = completed, magenta/amber = NG loop and alerts.
CYAN, CYAN_MID, CYAN_DIM = "#00e5ff", "#0a9fbd", "#0b4f61"
TEAL, TEAL_DIM = "#2be0b0", "#1a7a63"
MAGENTA, MAGENTA_DIM = "#ff3fd8", "#6e2463"
AMBER, AMBER_DIM = "#ffb020", "#6b4a12"
FG, STEEL, GRID, INK, BG = "#c8d6e5", "#5b6b80", "#26323f", "#03121a", "#060a12"
PULSE = [CYAN_DIM, "#0c7590", CYAN_MID, "#05c3e0", CYAN]  # breathing levels, dim -> bright
PULSE_DONE = [TEAL_DIM, "#1f9a7c", "#25bd96", TEAL]
STATUS_STYLE = {
    "working": f"bold {CYAN}",
    "blocked": f"bold {AMBER}",
    "done": TEAL,
    "idle": "#7f9bb8",
    "unknown": STEEL,
    "gone": MAGENTA_DIM,
}
STATUS_ICON = {"working": "◐", "blocked": "▲", "done": "✓", "idle": "○", "unknown": "?", "gone": "×"}
SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SUBSCRIPTIONS = [
    "workspace.metadata_updated", "workspace.updated", "workspace.closed",
    "tab.created", "tab.closed", "pane.created", "pane.closed", "pane.updated",
    "pane.exited", "pane.agent_detected",
]

BOX_W = 15  # outer width of a node box
GAP = 3  # width of the "──▸" connector
FULL_W = 1 + 4 * BOX_W + 3 * GAP  # columns needed by the diagram layout
COALESCE_S = 0.3  # max delay between the first event of a burst and the refresh
FPS = 8  # animation frame rate of the TUI


@dataclass
class Agent:
    role: str
    pane_id: str
    status: str = "gone"
    name: str = ""
    title: str = ""


@dataclass
class State:
    workspace_id: str
    label: str = ""
    phase: str | None = None
    loop: int = 0
    agents: list[Agent] = field(default_factory=list)
    error: str | None = None
    mode: str = "polling"
    warning: str | None = None  # non-fatal live-update problem, shown in the header
    updated: float = field(default_factory=time.time)

    @property
    def has_metadata(self) -> bool:
        return self.phase is not None or bool(self.agents)


def fetch_snapshot() -> dict:
    out = subprocess.run(
        ["herdr", "api", "snapshot"], capture_output=True, text=True, timeout=10, check=True
    ).stdout
    return json.loads(out)["result"]["snapshot"]


def full_pane_id(pane: str, workspace_id: str) -> str:
    return pane if ":" in pane else f"{workspace_id}:{pane}"


def build_state(workspace_id: str) -> State:
    state = State(workspace_id)
    try:
        snap = fetch_snapshot()
    except Exception as e:  # herdr not running, timeout, bad JSON
        state.error = f"snapshot failed: {e}"
        return state
    ws = next((w for w in snap.get("workspaces", []) if w.get("workspace_id") == workspace_id), None)
    if ws is None:
        state.error = f"workspace {workspace_id} not found"
        return state
    state.label = ws.get("label", "")
    tokens = ws.get("tokens") or {}
    phase = tokens.get("phase")
    state.phase = phase if phase in PHASES else (phase or None)
    try:
        state.loop = int(tokens.get("loop", 0))
    except ValueError:
        state.loop = 0

    panes = {p["pane_id"]: p for p in snap.get("panes", [])}
    agents = {a["pane_id"]: a for a in snap.get("agents", [])}
    roles = [("investigators", p) for p in tokens.get("investigators", "").split(",") if p.strip()]
    roles += [(r, tokens[r]) for r in ("worker", "reviewer") if tokens.get(r)]
    for role, pane in roles:
        pid = full_pane_id(pane.strip(), workspace_id)
        agent = Agent(role, pid)
        info = agents.get(pid) or panes.get(pid)
        if info:
            agent.status = info.get("agent_status", "unknown")
            agent.name = info.get("name") or info.get("agent") or ""
            agent.title = info.get("terminal_title_stripped", "")
        state.agents.append(agent)
    return state


def demo_state() -> State:
    """Dummy state for previewing the layout without herdr (--demo)."""
    ws = "demo"
    return State(
        ws, label="sample", phase="review", loop=1, mode="demo",
        agents=[
            Agent("investigators", f"{ws}:p1", "done", "claude"),
            Agent("investigators", f"{ws}:p2", "done", "claude"),
            Agent("worker", f"{ws}:p3", "idle", "claude"),
            Agent("reviewer", f"{ws}:p4", "working", "claude"),
        ],
    )


# ---------- rendering ----------
# `t` is the animation frame counter; t=None renders a static frame (used by --once).

Cell = tuple[str, str]  # (character, style)
HEAVY = {"─": "━", "│": "┃", "┌": "┏", "┘": "┛", "└": "┗", "┤": "┫"}
# Edge kind -> (base, tail, head) colors and whether packets travel along it.
FLOW = {
    "active": (CYAN_DIM, CYAN_MID, CYAN, True),
    "done": (TEAL_DIM, TEAL_DIM, TEAL_DIM, False),
    "future": (GRID, GRID, GRID, False),
    "ng": (MAGENTA_DIM, MAGENTA, AMBER, True),
    "ng_past": (MAGENTA_DIM, MAGENTA_DIM, MAGENTA_DIM, False),
}
NG_LIVE = {"decide", "work", "review"}  # phases during which the NG loop is in play
BORDERS = {"current": "╔═╗║╚╝", "done": "╭─╮│╰╯", "future": "┌─┐│└┘"}


def short_id(pane_id: str, workspace_id: str) -> str:
    prefix = f"{workspace_id}:"
    return pane_id[len(prefix):] if pane_id.startswith(prefix) else pane_id


def cells_text(cells: list[Cell]) -> Text:
    """Join cells into a Text, one span per run of equal style."""
    text = Text()
    run, run_style = "", None
    for ch, style in cells:
        if style != run_style and run:
            text.append(run, style=run_style)
            run = ""
        run, run_style = run + ch, style
    if run:
        text.append(run, style=run_style)
    return text


def pulse(t: int | None, levels: list[str]) -> str:
    """Breathing color: walk up and down the brightness levels, one step per 2 frames."""
    if t is None:
        return levels[-1]
    n = len(levels) - 1
    k = t // 2 % (2 * n)
    return levels[k if k <= n else 2 * n - k]


def paint_flow(chars: list[str], kind: str, t: int | None, period: int) -> list[Cell]:
    """Style edge cells given in flow order; animated kinds carry moving packets."""
    base, tail, head, animated = FLOW[kind]
    cells = []
    for k, ch in enumerate(chars):
        if kind == "done":
            cells.append((HEAVY.get(ch, ch), base))
        elif not animated or t is None:
            cells.append((ch, tail if animated else base))
        elif (pos := (k - t) % period) == 0:
            cells.append((HEAVY.get(ch, ch), f"bold {head}"))
        elif pos == period - 1:  # the cell just behind the head
            cells.append((HEAVY.get(ch, ch), tail))
        else:
            cells.append((ch, base))
    return cells


def phase_kind(phase: str, state: State) -> str:
    """current / done / future, relative to the reported phase."""
    if state.phase not in PHASES:
        return "future"
    cur, idx = PHASES.index(state.phase), PHASES.index(phase)
    if idx == cur:
        return "current"
    return "done" if idx < cur else "future"


def edge_kind(target: str, state: State) -> str:
    """Kind of the edge leading into `target`: it flows while `target` is current."""
    kind = phase_kind(target, state)
    if kind == "current":
        return "done" if target == "done" else "active"
    return kind


def agents_in(phase: str, state: State) -> list[Agent]:
    return [a for a in state.agents if ROLE_PHASE[a.role] == phase]


def status_text(status: str, t: int | None) -> Text:
    """Icon + status word; working spins, blocked flashes."""
    icon, style = STATUS_ICON.get(status, "?"), STATUS_STYLE.get(status, STEEL)
    if t is not None:
        if status == "working":
            icon = SPINNER[t % len(SPINNER)]
        elif status == "blocked" and t // 4 % 2:
            style = f"bold {AMBER_DIM}"
    return Text(f"{icon} {status}", style=style)


def agent_cell(agent: Agent, workspace_id: str, t: int | None) -> Text:
    cell = Text.assemble((f"{short_id(agent.pane_id, workspace_id)} ", f"bold {FG}"))
    cell.append_text(status_text(agent.status, t))
    return cell


def node_lines(phase: str, state: State, height: int, t: int | None) -> list[Text]:
    kind = phase_kind(phase, state)
    finished = state.phase == "done"
    if kind == "current":
        border = f"bold {pulse(t, PULSE_DONE if finished else PULSE)}"
        title, title_style = f"◆ {phase.upper()}", f"bold {INK} on {TEAL if finished else CYAN}"
    elif kind == "done":
        border, title, title_style = TEAL_DIM, f"✓ {phase.upper()}", TEAL
    else:
        border, title, title_style = GRID, phase.upper(), STEEL
    tl, h, tr, v, bl, br = BORDERS[kind]
    inner = BOX_W - 2
    body = [Text(title.center(inner), style=title_style)]
    for agent in agents_in(phase, state):
        line = Text(" ")
        line.append(f"{short_id(agent.pane_id, state.workspace_id):<3}", style=f"bold {FG}")
        line.append_text(status_text(agent.status, t))
        line.truncate(inner)
        line.pad_right(inner - line.cell_len)
        body.append(line)
    while len(body) < height - 2:
        body.append(Text(" " * inner))
    lines = [Text(tl + h * inner + tr, style=border)]
    for b in body:
        lines.append(Text(v, style=border) + b + Text(v, style=border))
    lines.append(Text(bl + h * inner + br, style=border))
    return lines


def node_row(phases: list[str], state: State, t: int | None) -> list[Text]:
    height = 3 + max((len(agents_in(p, state)) for p in phases), default=0)
    boxes = [node_lines(p, state, height, t) for p in phases]
    rows = []
    for i in range(height):
        row = Text(" ")
        for j, box in enumerate(boxes):
            if j:
                connector = paint_flow(list("──▸"), edge_kind(phases[j], state), t, period=4)
                row.append_text(cells_text(connector) if i == 1 else Text("   "))
            row.append_text(box[i])
        rows.append(row)
    return rows


def center_col(index: int) -> int:
    return 1 + index * (BOX_W + GAP) + BOX_W // 2


def edge_lines(state: State, t: int | None) -> list[Text]:
    """review -> verify (OK) and the review -> decide back-edge (NG) between the rows."""
    decide, review, left = center_col(1), center_col(3), center_col(0)
    grid = [[" "] * (review + 1) for _ in range(4)]  # rows: up, ng, ok, down
    grid[0][decide], grid[0][review] = "▲", "│"
    grid[1][decide + 1:review] = ["─"] * (review - decide - 1)
    grid[1][decide], grid[1][review] = "└", "┤"
    grid[2][left + 1:review] = ["─"] * (review - left - 1)
    grid[2][left], grid[2][review] = "┌", "┘"
    grid[3][left] = "▼"
    cells = [[(ch, "") for ch in row] for row in grid]

    ng_path = [(0, review), (1, review)] + [(1, x) for x in range(review - 1, decide - 1, -1)] + [(0, decide)]
    ok_path = [(0, review), (1, review), (2, review)] + [(2, x) for x in range(review - 1, left - 1, -1)] + [(3, left)]
    ok_kind = edge_kind("verify", state)
    ng_kind = ("ng" if state.phase in NG_LIVE else "ng_past") if state.loop else "future"
    paths = [(ng_path, ng_kind), (ok_path, ok_kind)]
    if ok_kind == "future":
        paths.reverse()  # the path painted last owns the shared stem under review
    for path, kind in paths:
        for (r, x), cell in zip(path, paint_flow([grid[r][x] for r, x in path], kind, t, period=6)):
            cells[r][x] = cell

    def label(row: int, a: int, b: int, text: str, style: str) -> None:
        start = (a + b - len(text)) // 2
        cells[row][start:start + len(text)] = [(ch, style) for ch in text]

    label(1, decide, review, f" NG ×{state.loop} ", f"bold {AMBER}" if state.loop else STEEL)
    label(2, left, review, " OK ", STEEL if ok_kind == "future" else f"bold {TEAL}")
    return [cells_text(row) for row in cells]


def link_style(mode: str, t: int | None) -> str:
    """Live-link dot: teal for events, amber for polling; blinks while animating."""
    bright, dim = {"events": (TEAL, TEAL_DIM), "polling": (AMBER, AMBER_DIM)}.get(mode, (STEEL, STEEL))
    return dim if t is not None and t // 5 % 2 else bright


def scan_bar(width: int, t: int | None) -> Text:
    """A thin rule with a bright segment sweeping left to right."""
    cells = [("─", GRID)] * width
    if t is not None:
        head = t * 2 % (width + 24)
        for i, color in enumerate([CYAN_DIM, CYAN_DIM, CYAN_MID, CYAN_MID, CYAN]):  # tail -> head
            if 0 <= (x := head - 4 + i) < width:
                cells[x] = ("━", color)
    return cells_text(cells)


def hud_line(state: State, t: int | None, title: str, label: bool, words: bool, clock: bool, link: bool) -> Text:
    hud = Text.assemble((title, f"bold {INK} on {CYAN}"))
    hud.append(f"  {state.workspace_id}", style=f"bold {FG}")
    if label and state.label:
        hud.append(f" {state.label}", style=STEEL)
    hud.append("  PHASE " if words else "  ", style=STEEL)
    hud.append((state.phase or "-").upper(), style=f"bold {CYAN}")
    hud.append("  LOOP " if words else "  ↺", style=STEEL)
    hud.append(f"{state.loop:02d}", style=f"bold {MAGENTA}" if state.loop else f"bold {FG}")
    if link:
        hud.append("  ")
        hud.append("●", style=link_style(state.mode, t))
        hud.append(" LINK " if label else " ", style=STEEL)
        hud.append(state.mode, style=FG)
    if clock:
        hud.append(f"  {time.strftime('%H:%M:%S', time.localtime(state.updated))}", style=STEEL)
    return hud


def header_lines(state: State, width: int, t: int | None) -> list[Text]:
    """HUD line that sheds parts as the pane narrows: label/LINK, PHASE/LOOP words, clock, then link."""
    title = " ◢ MAJI // FLOW MONITOR ◣ " if width >= 100 else " ◢ MAJI ◣ "
    wide = width > FULL_W
    variants = [(wide, True, True, True), (False, True, True, True), (False, False, True, True),
                (False, False, False, True), (False, False, False, False)]
    for label, words, clock, link in variants:
        hud = hud_line(state, t, title, label, words, clock, link)
        if hud.cell_len <= width - 1:
            break
    return [hud, scan_bar(max(width - 1, 1), t)]


def compact_lines(state: State, t: int | None) -> list[Text]:
    """One line per phase on a vertical rail, for panes narrower than FULL_W."""
    cur = PHASES.index(state.phase) if state.phase in PHASES else -1
    # A packet runs down the completed rail into the current row.
    packet = t // 2 % cur if t is not None and cur > 0 else -1
    finished = state.phase == "done"
    lines = []
    for i, phase in enumerate(PHASES):
        kind = phase_kind(phase, state)
        name = f"{phase.upper():<12}"
        if kind == "current":
            line = Text.assemble((" ◆ ", f"bold {pulse(t, PULSE_DONE if finished else PULSE)}"))
            line.append(name, style=f"bold {INK} on {TEAL if finished else CYAN}")
        elif kind == "done":
            line = Text.assemble((" ● ", f"bold {CYAN}") if i == packet else (" ┃ ", TEAL_DIM))
            line.append(name, style=TEAL)
        else:
            line = Text.assemble((" ┆ ", GRID))
            line.append(name, style=STEEL)
        if phase == "decide" and state.loop:
            blink = state.phase in NG_LIVE and t is not None and t // 3 % 2
            line.append(f" ↺ NG ×{state.loop}", style=f"bold {AMBER if blink else MAGENTA}")
        for agent in agents_in(phase, state):
            line.append(" ")
            line.append_text(agent_cell(agent, state.workspace_id, t))
        lines.append(line)
    return lines


def agent_table(state: State, t: int | None) -> list[Text]:
    lines = [Text()]
    for a in state.agents:
        line = Text.assemble((f" {a.role:<14}", STEEL))
        line.append(f"{short_id(a.pane_id, state.workspace_id):<8}", style=f"bold {FG}")
        status = status_text(a.status, t)
        status.pad_right(10 - status.cell_len)
        line.append_text(status)
        line.append(f" {a.name:<10.10}", style=f"bold {CYAN_MID}")
        line.append(f" {a.title}", style=STEEL)
        lines.append(line)
    return lines


def render_lines(state: State, width: int = FULL_W + 1, t: int | None = None) -> list[Text]:
    """Render the state; falls back to a compact list when width < FULL_W."""
    compact = width < FULL_W + 1
    lines = header_lines(state, width, t)
    if state.warning:
        lines.append(Text(f" ⚠ {state.warning}", style=f"bold {AMBER}"))

    if state.error:
        lines.append(Text(f" ✕ {state.error}", style=f"bold {MAGENTA}"))
    else:
        if not state.has_metadata:
            line = Text.assemble((" ◌ NO SIGNAL ", f"bold {AMBER}"))
            line.append(" No maji metadata reported for this workspace.", style=FG)
            lines.append(line)
            lines.append(Text(
                f" › herdr workspace report-metadata {state.workspace_id} --source maji --token phase=investigate ...",
                style=STEEL,
            ))
            lines.append(Text())
        if compact:
            lines += compact_lines(state, t)
        else:
            lines += node_row(PHASES[:4], state, t) + edge_lines(state, t) + node_row(PHASES[4:], state, t)
            if state.agents:
                lines += agent_table(state, t)

    for line in lines:
        line.truncate(max(width - 1, 1))  # never let Textual wrap a line
    return lines


def render(state: State, width: int = FULL_W + 1, t: int | None = None) -> Text:
    return Text("\n").join(render_lines(state, width, t))


# ---------- live updates ----------

def socket_path() -> str:
    if p := os.environ.get("HERDR_SOCKET_PATH"):
        return p
    for cand in (Path(os.environ.get("TMPDIR", "/tmp")) / "herdr.sock", Path.home() / ".config/herdr/herdr.sock"):
        if cand.exists():
            return str(cand)
    return ""


def subscribe() -> socket.socket:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(socket_path())
    req = {"id": "maji-viewer", "method": "events.subscribe",
           "params": {"subscriptions": [{"type": t} for t in SUBSCRIPTIONS]}}
    sock.sendall((json.dumps(req) + "\n").encode())
    sock.settimeout(5)
    reply = b""
    while not reply.endswith(b"\n"):
        chunk = sock.recv(65536)
        if not chunk:
            raise ConnectionError("socket closed")
        reply += chunk
    first = json.loads(reply.split(b"\n", 1)[0])
    if "error" in first:
        raise ConnectionError(first["error"].get("message", "subscribe failed"))
    return sock


def watch(workspace_id: str, publish, stop: threading.Event) -> None:
    """Publish a fresh State on every herdr event (or every 1s when polling)."""
    sock = None
    warning = None
    while not stop.is_set():
        try:
            if sock is None:
                try:
                    sock = subscribe()
                    warning = None
                except Exception as e:
                    sock, warning = None, f"events unavailable ({e}); polling"
            state = build_state(workspace_id)
            state.mode = "events" if sock else "polling"
            state.warning = warning
            publish(state)
            if sock is None:
                stop.wait(1)
                continue
            sock.settimeout(5)  # periodic refresh even without events
            if not sock.recv(65536):
                raise ConnectionError("event socket closed")
            # Coalesce a burst, but refresh at most COALESCE_S after its first event
            # so a steady stream of events cannot starve the display.
            deadline = time.monotonic() + COALESCE_S
            while (left := deadline - time.monotonic()) > 0:
                sock.settimeout(left)
                if not sock.recv(65536):
                    raise ConnectionError("event socket closed")
        except socket.timeout:
            pass
        except Exception as e:  # keep the viewer alive; retry after a pause
            warning = f"{type(e).__name__}: {e}; retrying"
            if sock is not None:
                sock.close()
                sock = None
            stop.wait(1)


def run_tui(workspace_id: str, demo: bool = False) -> None:
    from textual import events
    from textual.app import App, ComposeResult
    from textual.geometry import Region
    from textual.strip import Strip
    from textual.widget import Widget

    class Flow(Widget):
        """Line-API view: only the lines that changed since the last frame are repainted."""

        def __init__(self) -> None:
            super().__init__(id="flow")
            self._lines: list[Text] = []
            self._strips: list[Strip] = []

        def show(self, lines: list[Text]) -> None:
            old_lines, old_strips = self._lines, self._strips
            self._lines, self._strips = lines, []
            for y, line in enumerate(lines):
                if y < len(old_lines) and line == old_lines[y]:
                    self._strips.append(old_strips[y])
                else:
                    self._strips.append(Strip(line.render(self.app.console)).apply_style(self.rich_style))
                    self.refresh(Region(0, y, self.size.width, 1))
            if len(old_lines) > len(lines):
                self.refresh(Region(0, len(lines), self.size.width, len(old_lines) - len(lines)))

        def render_line(self, y: int) -> Strip:
            strip = self._strips[y] if y < len(self._strips) else Strip.blank(0)
            return strip.adjust_cell_length(self.size.width, self.rich_style)

    class MajiViewer(App):
        CSS = f"Screen {{ background: {BG}; }} #flow {{ height: 1fr; color: {FG}; }}"
        BINDINGS = [("q", "quit", "Quit")]

        def __init__(self) -> None:
            super().__init__()
            self._watch_stop = threading.Event()
            self._latest: State | None = None
            self._frame = 0
            self._width = 0

        def compose(self) -> ComposeResult:
            yield Flow()

        def on_mount(self) -> None:
            self.title = "maji"
            if demo:
                self._latest = demo_state()
            else:
                threading.Thread(
                    target=watch, args=(workspace_id, self.publish, self._watch_stop), daemon=True
                ).start()
            self.set_interval(1 / FPS, self.tick)

        def tick(self) -> None:
            self._frame += 1
            self.show()

        def publish(self, state: State) -> None:
            try:
                self.call_from_thread(self.show, state)
            except Exception:
                self._watch_stop.set()  # app is shutting down

        def show(self, state: State | None = None, width: int | None = None) -> None:
            self._latest = state or self._latest
            self._width = width or self._width or self.size.width
            if self._latest:
                self.query_one(Flow).show(render_lines(self._latest, self._width, self._frame))

        def on_resize(self, event: events.Resize) -> None:
            # self.size is not updated yet while handling Resize; use the event's size.
            self.show(width=event.size.width)

        def on_unmount(self) -> None:
            self._watch_stop.set()

    MajiViewer().run()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--workspace", default=os.environ.get("HERDR_WORKSPACE_ID"))
    parser.add_argument("--once", action="store_true", help="print the current state as plain text and exit")
    parser.add_argument("--demo", action="store_true", help="show dummy sample data instead of the live state")
    args = parser.parse_args()
    if args.demo and args.once:
        print(render(demo_state(), shutil.get_terminal_size((FULL_W + 1, 24)).columns).plain.rstrip())
        sys.exit(0)
    if args.demo:
        run_tui("demo", demo=True)
        return
    if not args.workspace:
        sys.exit("no workspace: pass --workspace or run inside herdr")
    if args.once:
        state = build_state(args.workspace)
        state.mode = "once"
        print(render(state, shutil.get_terminal_size((FULL_W + 1, 24)).columns).plain.rstrip())
        sys.exit(1 if state.error else 0)
    run_tui(args.workspace)


if __name__ == "__main__":
    main()
