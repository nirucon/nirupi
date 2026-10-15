#!/usr/bin/env python3
"""NIRU status panel — a small, consistent TUI for the status-bar pop-ups.

Reads a simple spec on stdin and draws a framed, palette-coloured panel that
always fits and closes on any key. Used by the battery/disk/weather pop-ups so
they all look and behave the same.

Spec (line based, rendered in the order given):
  @title   Battery
  @sub     ThinkPad · BAT0
  @accent  cyan            (cyan|green|yellow|red|blue|muted; default cyan)
  @bar     83              a 0..100 bar, drawn on the following @row
  @row     Charge|83 %     a label/value row
  @note    any text        a dim line
  other text               also a dim line
"""
import curses
import os
import sys

TITLE = "NIRUPI"
SUB = ""
ACCENT = "cyan"
ITEMS = []     # ordered: ("sub"|"row"|"note", label, value, pct)


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
            label, _, value = line[5:].partition("|")
            ITEMS.append(("row", label.strip(), value.strip(), pending_bar))
            pending_bar = None
        elif line.startswith("@note "):
            ITEMS.append(("note", line[6:].strip(), "", None))
        else:
            ITEMS.append(("note", line.strip(), "", None))


def read_palette():
    pal = {}
    path = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
                        "nirupi", "theme", "status.env")
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
    c_label = curses.color_pair(2)
    c_value = curses.color_pair(3)
    c_muted = curses.color_pair(4)
    c_warn = curses.color_pair(5)
    c_ok = curses.color_pair(6)

    rows = [it for it in ITEMS if it[0] == "row"]
    notes = [it for it in ITEMS if it[0] == "note"]
    label_w = max([len(r[1]) for r in rows] or [0])
    value_w = max([len(r[2]) for r in rows] or [0])
    bar_w = 12 if any(r[3] is not None for r in rows) else 0
    row_w = label_w + 2 + value_w + (bar_w + 2 if bar_w else 0)
    notes_w = max([len(n[1]) + 2 for n in notes] or [0])
    inner = max(row_w, len(TITLE) + 6, len(SUB) + 4, notes_w)
    box_w = min(w - 2, max(inner + 4, 30))
    left = max(0, (w - box_w) // 2)
    cw = box_w - 2                    # inner cell count

    n_sub = 1 if SUB else 0
    total = 2 + n_sub + len(ITEMS) + 1
    top = max(0, (h - total) // 2)

    label = " %s " % TITLE
    put(scr, top, left, "\u256d" + label + "\u2500" * max(0, cw - len(label)) + "\u256e",
        c_accent | curses.A_BOLD)
    y = top + 1
    if SUB:
        put(scr, y, left, "\u2502" + (" %s" % SUB), c_muted)
        put(scr, y, left + box_w - 1, "\u2502", c_accent)
        y += 1

    def rowline(lab, val, pct):
        put(scr, y, left, "\u2502", c_accent)
        put(scr, y, left + 2, lab.ljust(label_w), c_label)
        vx = left + 2 + label_w + 2
        put(scr, y, vx, val.ljust(value_w),
            c_warn if (pct is not None and pct <= 15) else c_value)
        if pct is not None:
            filled = int(pct / 100 * bar_w)
            col = c_warn if pct <= 15 else (c_ok if pct >= 50 else c_muted)
            put(scr, y, vx + value_w + 1,
                "\u2588" * filled + "\u2591" * (bar_w - filled), col)
        put(scr, y, left + box_w - 1, "\u2502", c_accent)

    for it in ITEMS:
        if it[0] == "row":
            rowline(it[1], it[2], it[3])
        else:
            put(scr, y, left, "\u2502", c_accent)
            put(scr, y, left + 2, it[1], c_muted)
            put(scr, y, left + box_w - 1, "\u2502", c_accent)
        y += 1

    put(scr, y, left, "\u2570" + "\u2500" * cw + "\u256f", c_accent | curses.A_BOLD)
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
            pairs = [("accent", ACCENT if ACCENT in pal else "cyan"),
                     ("label", "muted"), ("value", "fg"), ("muted", "muted"),
                     ("warn", "red"), ("ok", "green")]
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
        print("%s%s" % (TITLE, (" — " + SUB) if SUB else ""))
        width = max([len(r[1]) for r in ITEMS if r[0] == "row"] or [0])
        for it in ITEMS:
            if it[0] == "row":
                print("  %-*s %s%s" % (width, it[1], it[2],
                                       ("  %d%%" % it[3]) if it[3] is not None else ""))
            else:
                print("  " + it[1])
