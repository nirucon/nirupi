#!/usr/bin/env python3
"""NIRU status panel — a small, consistent TUI for the status-bar pop-ups.

Reads a simple spec on stdin and draws a framed, palette-coloured panel that
always fits and closes on any key. Used by the battery/disk/weather/updates
pop-ups so they all look and behave the same.

Spec (line based):
  @title   Battery
  @sub     ThinkPad · BAT0
  @accent  cyan            (cyan|green|yellow|red|blue|muted; default cyan)
  @bar     83              0..100, optional used by the following line
  @row     Charge|83 %
  @row     Health|79 %
  @note    Discharging — about 2 h 10 m left
  @kv      Uptime|3 h 12 m
  plain text                (dim note)
Lines starting with # and blank lines are ignored.
"""
import curses
import os
import sys

TITLE = "NIRUPI"
SUB = ""
ACCENT = "cyan"
ROWS = []          # list of (label, value, pct_or_None)
NOTES = []         # list of str


def parse(stdin):
    global TITLE, SUB, ACCENT
    pending_bar = None
    for raw in stdin:
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("@title "):
            TITLE = line[7:].strip()
        elif line.startswith("@sub "):
            SUB = line[5:].strip()
        elif line.startswith("@accent "):
            ACCENT = line[8:].strip()
        elif line.startswith("@bar "):
            try:
                pending_bar = max(0, min(100, int(float(line[5:].strip()))))
            except ValueError:
                pending_bar = None
        elif line.startswith("@row "):
            body = line[5:]
            label, _, value = body.partition("|")
            ROWS.append((label.strip(), value.strip(), pending_bar))
            pending_bar = None
        elif line.startswith("@kv "):
            body = line[4:]
            label, _, value = body.partition("|")
            ROWS.append((label.strip(), value.strip(), pending_bar))
            pending_bar = None
        elif line.startswith("@note "):
            NOTES.append(line[6:].strip())
        else:
            NOTES.append(line.strip())
    # trailing note after rows
    return


def read_palette():
    """Map palette tokens to nearest xterm-256 colour pairs (best effort)."""
    pal = {}
    for path in (os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
                              "nirupi", "theme", "status.env"),):
        try:
            with open(path) as fh:
                for line in fh:
                    if "=" in line and not line.startswith("#"):
                        k, v = line.split("=", 1)
                        pal[k.strip()] = v.strip().strip('"').lstrip("#")
        except OSError:
            pass
    want = {"red": ("NIRUPI_C_RED", "b87878"),
            "green": ("NIRUPI_C_GREEN", "83a18b"),
            "yellow": ("NIRUPI_C_YELLOW", "b5a47e"),
            "blue": ("NIRUPI_C_BLUE", "819eb5"),
            "cyan": ("NIRUPI_C_CYAN", "83a9a7"),
            "muted": ("NIRUPI_C_MUTED", "a8a8a8"),
            "fg": ("NIRUPI_FG", "e5e5e5")}
    out = {}
    for key, (var, fallback) in want.items():
        hexv = pal.get(var) or fallback
        try:
            r, g, b = (int(hexv[i:i + 2], 16) for i in (0, 2, 4))
        except (ValueError, IndexError):
            r = g = b = 200
        out[key] = 16 + (r * 5 // 255) * 36 + (g * 5 // 255) * 6 + (b * 5 // 255)
    return out


def put(scr, y, x, text, attr=0):
    h, w = scr.getmaxyx()
    if y < 0 or y >= h or x < 0 or x >= w:
        return
    try:
        scr.addstr(y, x, text[:max(0, w - x - 1)], attr)
    except curses.error:
        pass


def render(scr, colors):
    scr.erase()
    h, w = scr.getmaxyx()
    c_accent = curses.color_pair(1)
    c_labels = curses.color_pair(2)
    c_values = curses.color_pair(3)
    c_muted = curses.color_pair(4)
    c_warn = curses.color_pair(5)
    c_ok = curses.color_pair(6)
    c_bold = curses.A_BOLD

    # geometry: inner content width
    label_w = max([len(r[0]) for r in ROWS] or [0])
    value_w = max([len(r[1]) for r in ROWS] or [0])
    bar_w = 12 if any(r[2] is not None for r in ROWS) else 0
    content = label_w + 2 + value_w + (bar_w + 1 if bar_w else 0)
    inner = max(content, len(TITLE) + 4, len(SUB) + 2,
                max([len(n) for n in NOTES] or [0]))
    box_w = min(w - 2, inner + 4)
    left = max(0, (w - box_w) // 2)

    # vertical centering
    body_h = len(ROWS) + (1 if NOTES else 0) + len(NOTES)
    total = body_h + 4          # top border, blank line, bottom border, pad
    top = max(0, (h - total) // 2)

    # top border with embedded title
    label = " %s " % TITLE
    bar = "\u2500" * max(0, box_w - 2 - len(label))
    put(scr, top, left, "\u256d" + label + bar + "\u256e", c_accent | c_bold)
    if SUB:
        sub = " %s " % SUB
        put(scr, top + 1, left, "\u2502" + sub, c_muted)
        put(scr, top + 1, left + box_w - 1, "\u2502", c_accent)

    y = top + 2
    for lab, val, pct in ROWS:
        put(scr, y, left, "\u2502", c_accent)
        put(scr, y, left + 2, lab.ljust(label_w), c_labels)
        put(scr, y, left + 2 + label_w + 2, val.ljust(value_w),
            c_warn if (pct is not None and pct <= 15) else c_values)
        if pct is not None:
            filled = int(pct / 100 * bar_w)
            bx = left + 2 + label_w + 2 + value_w + 1
            col = c_warn if pct <= 15 else (c_ok if pct >= 50 else c_muted)
            put(scr, y, bx, "\u2588" * filled + "\u2591" * (bar_w - filled), col)
        put(scr, y, left + box_w - 1, "\u2502", c_accent)
        y += 1

    if NOTES:
        y += 1
        for note in NOTES:
            put(scr, y, left, "\u2502", c_accent)
            put(scr, y, left + 2, note, c_muted)
            put(scr, y, left + box_w - 1, "\u2502", c_accent)
            y += 1

    put(scr, y, left, "\u2570" + "\u2500" * (box_w - 2) + "\u256f", c_accent | c_bold)
    hint = "press any key to close"
    put(scr, y + 2, max(0, (w - len(hint)) // 2), hint, c_muted)
    scr.refresh()


def main(scr):
    curses.curs_set(0)
    try:
        curses.use_default_colors()
    except curses.error:
        pass
    pal = read_palette()
    if curses.has_colors():
        try:
            curses.start_color()
            pairs = [("accent", ACCENT if ACCENT in pal else "cyan"), ("labels", "muted"),
                     ("values", "fg"), ("muted", "muted"), ("warn", "red"), ("ok", "green")]
            for i, (_, key) in enumerate(pairs, start=1):
                curses.init_pair(i, pal.get(key, 250), -1)
        except curses.error:
            pass
    render(scr, pal)
    scr.timeout(-1)
    scr.getch()


if __name__ == "__main__":
    parse(sys.stdin)
    try:
        curses.wrapper(main)
    except curses.error:
        # No terminal (e.g. piped): print a plain version.
        print("%s%s" % (TITLE, (" — " + SUB) if SUB else ""))
        for lab, val, pct in ROWS:
            print("  %-*s %s%s" % (max([len(r[0]) for r in ROWS] or [0]), lab, val,
                                   ("  %d%%" % pct) if pct is not None else ""))
        for n in NOTES:
            print("  " + n)
