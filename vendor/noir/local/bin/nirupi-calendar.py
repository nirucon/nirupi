#!/usr/bin/env python3
"""Minimal NIRU Noir calendar TUI: Swedish, Monday-first, ISO week numbers.

Keys: left/right (or h/l) change month, up/down (or k/j) change year,
t = today, q/Esc = quit.
"""
import calendar
import curses
import datetime

MONTHS = ["", "januari", "februari", "mars", "april", "maj", "juni",
          "juli", "augusti", "september", "oktober", "november", "december"]
WD = ["Man", "Tis", "Ons", "Tor", "Fre", "Lor", "Son"]
# Nicer with the actual three-letter forms; ASCII-safe fallback is fine too.
WD = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]


def draw(stdscr, y, m, today):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    width = 5 + 7 * 4
    left = max(0, (w - width) // 2)
    title = f"{MONTHS[m]} {y}"
    try:
        stdscr.addstr(1, max(0, (w - len(title)) // 2), title, curses.A_BOLD)
        stdscr.addstr(3, left, "     " + "".join(f"{d:>3} " for d in WD), curses.A_DIM)
        for r, week in enumerate(calendar.Calendar(0).monthdayscalendar(y, m)):
            row = 4 + r
            wk = next((datetime.date(y, m, d).isocalendar()[1] for d in week if d), "")
            stdscr.addstr(row, left, f"v{wk:>2} " if wk != "" else "     ", curses.A_DIM)
            for i, d in enumerate(week):
                x = left + 5 + i * 4
                if d == 0:
                    stdscr.addstr(row, x, "    ")
                else:
                    attr = curses.A_REVERSE if (y == today.year and m == today.month
                                                and d == today.day) else curses.A_NORMAL
                    stdscr.addstr(row, x, f"{d:>3} ", attr)
        footer = "←/→ månad   ↑/↓ år   t idag   q avsluta"
        stdscr.addstr(h - 2, max(0, (w - len(footer)) // 2), footer, curses.A_DIM)
    except curses.error:
        pass
    stdscr.refresh()


def main(stdscr):
    curses.curs_set(0)
    today = datetime.date.today()
    y, m = today.year, today.month
    while True:
        draw(stdscr, y, m, today)
        k = stdscr.getch()
        if k in (ord('q'), 27):
            break
        elif k in (curses.KEY_LEFT, ord('h')):
            m -= 1
            if m < 1:
                m, y = 12, y - 1
        elif k in (curses.KEY_RIGHT, ord('l'), ord('n')):
            m += 1
            if m > 12:
                m, y = 1, y + 1
        elif k in (curses.KEY_UP, ord('k')):
            y -= 1
        elif k in (curses.KEY_DOWN, ord('j')):
            y += 1
        elif k == ord('t'):
            y, m = today.year, today.month


if __name__ == "__main__":
    curses.wrapper(main)
