#!/usr/bin/env python3
"""NIRU calendar — a clean, keyboard-first month view.

English UI with a Monday-first week (Mon..Sun) and ISO week numbers. It can
optionally read a Google Calendar "secret iCal" (ICS) URL, set from inside the
TUI with `s`; that day's events are listed next to the grid and `o` opens the
selected day in Google Calendar (for editing, since ICS here is read-only).

The drawing is adaptive: every line is truncated to the window width and the
event list only uses the rows that fit, so it never wraps or spills in a small
floating terminal.

Keys: arrows/hjkl move the day, PgUp/PgDn month, </> year, t today,
      s settings (ICS URL), o open in Google Calendar, q quit.
"""
import calendar
import curses
import datetime
import os
import subprocess
import urllib.request

MONTHS = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"]
WD = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

CONF_DIR = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "nirupi")
CONF = os.path.join(CONF_DIR, "calendar.conf")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "nirupi", "calendar.ics")
ICS_TTL = 900  # seconds


# ── config ───────────────────────────────────────────────────────────────────
def read_conf():
    conf = {"ICS_URL": ""}
    try:
        with open(CONF) as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                conf[k.strip()] = v.strip().strip('"')
    except OSError:
        pass
    return conf


def write_conf(conf):
    os.makedirs(CONF_DIR, exist_ok=True)
    tmp = CONF + ".tmp"
    with open(tmp, "w") as fh:
        fh.write("# NIRU calendar settings (user-owned).\n")
        fh.write("# Google Calendar -> Settings -> your calendar -> "
                 "\"Secret address in iCal format\".\n")
        fh.write("ICS_URL=%s\n" % conf.get("ICS_URL", ""))
    os.replace(tmp, CONF)


# ── ICS fetch + parse ────────────────────────────────────────────────────────
def fetch_ics(url, force=False):
    """Return ICS text from the cache, refreshing when stale. '' on failure."""
    if not url:
        return ""
    try:
        age = datetime.datetime.now().timestamp() - os.path.getmtime(CACHE)
        if not force and age < ICS_TTL:
            with open(CACHE, encoding="utf-8", errors="replace") as fh:
                return fh.read()
    except OSError:
        pass
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "nirupi-calendar"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            text = resp.read().decode("utf-8", "replace")
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        with open(CACHE, "w", encoding="utf-8") as fh:
            fh.write(text)
        return text
    except Exception:
        try:
            with open(CACHE, encoding="utf-8", errors="replace") as fh:
                return fh.read()
        except OSError:
            return ""


def unfold(lines):
    out = []
    for line in lines:
        if line[:1] in (" ", "\t") and out:
            out[-1] += line[1:]
        else:
            out.append(line)
    return out


def parse_dt(value, params):
    value = value.strip()
    if "T" in value:
        core = value.rstrip("Z")
        try:
            dt = datetime.datetime.strptime(core[:15], "%Y%m%dT%H%M%S")
        except ValueError:
            dt = datetime.datetime.strptime(core[:13], "%Y%m%dT%H%M")
        if value.endswith("Z"):
            dt = dt.replace(tzinfo=datetime.timezone.utc).astimezone().replace(tzinfo=None)
        return dt
    return datetime.datetime.strptime(value[:8], "%Y%m%d").date()


def parse_rrule(value):
    rule = {}
    for part in value.split(";"):
        if "=" not in part:
            continue
        k, v = part.split("=", 1)
        rule[k.strip().upper()] = v.strip()
    return rule


def parse_events(text):
    events = []
    cur = None
    for line in unfold(text.splitlines()):
        up = line.upper()
        if up.startswith("BEGIN:VEVENT"):
            cur = {}
        elif up.startswith("END:VEVENT"):
            if cur and "start" in cur:
                events.append(cur)
            cur = None
        elif cur is not None:
            key, _, val = line.partition(":")
            base = key.split(";", 1)[0].upper()
            params = {}
            if ";" in key:
                for p in key.split(";")[1:]:
                    if "=" in p:
                        pk, pv = p.split("=", 1)
                        params[pk.upper()] = pv
            if base == "DTSTART":
                cur["start"] = parse_dt(val, params)
            elif base == "DTEND":
                cur["end"] = parse_dt(val, params)
            elif base == "SUMMARY":
                cur["summary"] = val.replace("\\,", ",").replace("\\n", " ").strip()
            elif base == "RRULE":
                cur["rrule"] = parse_rrule(val)
    return events


def occurrences(ev, start, end):
    """Yield dates in [start, end] on which ev occurs (basic RRULE support)."""
    ds = ev["start"]
    if isinstance(ds, datetime.datetime):
        base = ds.date()
        tm = ds.strftime("%H:%M")
    else:
        base = ds
        tm = ""
    rrule = ev.get("rrule")
    if not rrule:
        if start <= base <= end:
            yield base, tm
        return
    freq = rrule.get("FREQ", "").upper()
    try:
        interval = max(1, int(rrule.get("INTERVAL", "1")))
    except ValueError:
        interval = 1
    count = int(rrule["COUNT"]) if rrule.get("COUNT", "").isdigit() else None
    until = None
    if rrule.get("UNTIL"):
        u = rrule["UNTIL"].rstrip("Z")
        until = datetime.datetime.strptime(u[:8], "%Y%m%d").date()
    byday = [d[-2:].upper() for d in rrule.get("BYDAY", "").split(",") if d]
    wdmap = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}

    produced = 0
    cur = base
    guard = 0
    while cur <= end and guard < 3000:
        guard += 1
        if until and cur > until:
            break
        hit = False
        if freq == "WEEKLY":
            if byday:
                hit = cur.weekday() in [wdmap[d] for d in byday if d in wdmap]
            else:
                hit = cur.weekday() == base.weekday()
        elif freq in ("DAILY", ""):
            hit = True
        elif freq == "MONTHLY":
            hit = cur.day == base.day
        elif freq == "YEARLY":
            hit = (cur.month, cur.day) == (base.month, base.day)
        if hit:
            produced += 1
            if count is not None and produced > count:
                break
            if start <= cur <= end:
                yield cur, tm
        if freq == "WEEKLY" and not byday:
            cur += datetime.timedelta(weeks=interval)
        elif freq == "MONTHLY":
            m = cur.month - 1 + interval
            cur = cur.replace(year=cur.year + m // 12, month=m % 12 + 1)
        elif freq == "YEARLY":
            cur = cur.replace(year=cur.year + interval)
        else:
            cur += datetime.timedelta(days=interval)
        if count is not None and produced >= count:
            break
    return


def add_months(d, n):
    y = d.year + (d.month - 1 + n) // 12
    m = (d.month - 1 + n) % 12 + 1
    last = calendar.monthrange(y, m)[1]
    return d.replace(year=y, month=m, day=min(d.day, last))


def events_for(events, day):
    items = []
    for ev in events:
        for d, tm in occurrences(ev, day, day):
            if d == day:
                items.append((tm or "  all-day", ev.get("summary", "(no title)")))
    items.sort()
    return items


# ── drawing ──────────────────────────────────────────────────────────────────
def put(stdscr, y, x, text, attr=0):
    """Draw text, truncated so it never wraps or touches the last cell."""
    h, w = stdscr.getmaxyx()
    if y < 0 or y >= h or x < 0 or x >= w:
        return
    text = text[:max(0, w - x - 1)]
    try:
        stdscr.addstr(y, x, text, attr)
    except curses.error:
        pass


def draw(stdscr, state):
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    sel = state["sel"]
    y, m = sel.year, sel.month
    today = datetime.date.today()

    grid_w = 4 + 7 * 3          # week column + 7 day cells (3 wide each)
    left = max(0, (w - grid_w) // 2)

    title = "%s %d" % (MONTHS[m - 1], y)
    put(stdscr, 1, left, title, curses.A_BOLD)
    put(stdscr, 1, left + len(title) + 2, "Week %d" % sel.isocalendar()[1], curses.A_DIM)

    put(stdscr, 3, left, "    " + "".join("%-3s" % d for d in WD), curses.A_DIM)
    cal = calendar.Calendar(0)
    row = 4
    for week in cal.monthdatescalendar(y, m):
        put(stdscr, row, left, "w%02d " % week[0].isocalendar()[1], curses.A_DIM)
        for i, day in enumerate(week):
            attr = curses.A_NORMAL
            if day.month != m or i >= 5:
                attr |= curses.A_DIM
            if day == today:
                attr |= curses.A_REVERSE
            if day == sel:
                attr |= curses.A_BOLD
            put(stdscr, row, left + 4 + i * 3, "%3d" % day.day, attr)
        row += 1

    footer_row = h - 2
    msg_row = h - 3
    ev_top = row + 1
    avail = footer_row - ev_top - 1     # rows available for the events panel
    if avail > 0:
        conf = state["conf"]
        if conf.get("ICS_URL"):
            items = events_for(state["events"], sel)
            put(stdscr, ev_top, left, "Events — %s" % sel.strftime("%a %d %b %Y"), curses.A_BOLD)
            if items:
                for i, (tm, summary) in enumerate(items[:max(0, avail - 1)]):
                    put(stdscr, ev_top + 1 + i, left, "  %-8s %s" % (tm, summary))
            else:
                put(stdscr, ev_top + 1, left, "  (none today)", curses.A_DIM)
        elif avail >= 2:
            put(stdscr, ev_top, left, "No calendar synced — press s to add a Google iCal URL.",
                curses.A_DIM)

    if state.get("msg"):
        put(stdscr, msg_row, left, state["msg"], curses.A_DIM)
    footer = "</> day  PgUp/Dn month  t today  s sync  o Google  q quit"
    put(stdscr, footer_row, max(0, (w - len(footer)) // 2), footer, curses.A_DIM)
    stdscr.refresh()


def prompt(stdscr, label, initial=""):
    h, w = stdscr.getmaxyx()
    y = h - 3
    put(stdscr, y, 2, " " * (w - 4))
    put(stdscr, y, 3, label + initial, curses.A_BOLD)
    stdscr.refresh()
    curses.echo()
    curses.curs_set(1)
    try:
        stdscr.move(y, min(w - 2, 3 + len(label) + len(initial)))
        raw = stdscr.getstr(y, 3 + len(label), max(1, w - 5 - len(label))).decode("utf-8", "replace")
    except curses.error:
        raw = ""
    finally:
        curses.noecho()
        curses.curs_set(0)
    return raw or initial


def open_google(day):
    url = "https://calendar.google.com/calendar/r/day/%d/%d/%d" % (day.year, day.month, day.day)
    for opener in (["xdg-open", url], ["gio", "open", url]):
        try:
            subprocess.Popen(opener, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
            return True
        except OSError:
            continue
    return False


# ── main ─────────────────────────────────────────────────────────────────────
def main(stdscr):
    curses.curs_set(0)
    try:
        curses.use_default_colors()
    except curses.error:
        pass
    conf = read_conf()
    today = datetime.date.today()
    state = {"sel": today, "conf": conf, "msg": "", "events": []}
    if conf.get("ICS_URL"):
        state["events"] = parse_events(fetch_ics(conf["ICS_URL"]))

    while True:
        draw(stdscr, state)
        ch = stdscr.getch()
        sel = state["sel"]
        state["msg"] = ""
        if ch in (ord("q"), 27):
            break
        elif ch == curses.KEY_RESIZE:
            continue
        elif ch in (curses.KEY_LEFT, ord("h")):
            sel -= datetime.timedelta(days=1)
        elif ch in (curses.KEY_RIGHT, ord("l")):
            sel += datetime.timedelta(days=1)
        elif ch in (curses.KEY_UP, ord("k")):
            sel -= datetime.timedelta(days=7)
        elif ch in (curses.KEY_DOWN, ord("j")):
            sel += datetime.timedelta(days=7)
        elif ch == curses.KEY_PPAGE:
            sel = add_months(sel, -1)
        elif ch == curses.KEY_NPAGE:
            sel = add_months(sel, 1)
        elif ch == ord("<"):
            sel = add_months(sel, -12)
        elif ch == ord(">"):
            sel = add_months(sel, 12)
        elif ch == ord("t"):
            sel = today
        elif ch == ord("o"):
            if not open_google(sel):
                state["msg"] = "Could not open a browser."
        elif ch == ord("s"):
            url = prompt(stdscr, "Google iCal URL (empty clears): ")
            conf["ICS_URL"] = url.strip()
            write_conf(conf)
            state["conf"] = conf
            state["events"] = parse_events(fetch_ics(conf["ICS_URL"], force=True)) if conf["ICS_URL"] else []
            state["msg"] = "Saved." if conf["ICS_URL"] else "Calendar sync disabled."
        state["sel"] = sel


if __name__ == "__main__":
    curses.wrapper(main)
