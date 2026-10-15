#!/usr/bin/env python3
"""NIRU calendar — a clean, keyboard-first month view.

English UI, Monday-first week (Mon..Sun), ISO week numbers. It can read one or
more Google Calendar "secret iCal" (ICS) URLs, added from inside the TUI with
`s`; the selected day's events are listed and `o` opens that day in Google
Calendar (for editing, since ICS here is read-only).

Drawing is adaptive (lines are truncated and only the rows that fit are used),
so it never wraps in a small floating terminal. The selected day is a highlighted
box you move around; today stays marked even when you navigate away.

Keys: arrows/hjkl move the day, PgUp/PgDn month, </> year, t today,
      s add an iCal URL, x clear all iCal URLs, o open in Google, q quit.
"""
import calendar
import curses
import datetime
import hashlib
import os
import subprocess
import urllib.request

MONTHS = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"]
WD = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

CONF_DIR = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "nirupi")
CONF = os.path.join(CONF_DIR, "calendar.conf")
CACHE_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "nirupi")
ICS_TTL = 900  # seconds


# ── config ───────────────────────────────────────────────────────────────────
def read_conf():
    urls = []
    try:
        with open(CONF) as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                if k.strip() == "ICS_URL":
                    v = v.strip().strip('"')
                    if v and v not in urls:
                        urls.append(v)
    except OSError:
        pass
    return {"ICS_URLS": urls}


def write_conf(conf):
    os.makedirs(CONF_DIR, exist_ok=True)
    tmp = CONF + ".tmp"
    with open(tmp, "w") as fh:
        fh.write("# NIRU calendar settings (user-owned; edited in the TUI with `s`).\n")
        fh.write("# Google Calendar -> Settings -> <calendar> -> \"Secret address in iCal format\".\n")
        for u in conf.get("ICS_URLS", []):
            fh.write("ICS_URL=%s\n" % u)
    os.replace(tmp, CONF)


# ── ICS fetch + parse ────────────────────────────────────────────────────────
def fetch_ics(url, force=False):
    """Return (text, error). Refreshes the per-URL cache when stale."""
    if not url:
        return "", "no url"
    url = url.replace("webcal://", "https://", 1)
    cache = os.path.join(CACHE_DIR, "calendar-%s.ics" % hashlib.sha1(url.encode()).hexdigest()[:12])
    try:
        age = datetime.datetime.now().timestamp() - os.path.getmtime(cache)
        if not force and age < ICS_TTL:
            with open(cache, encoding="utf-8", errors="replace") as fh:
                return fh.read(), ""
    except OSError:
        pass
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) nirupi-calendar",
            "Accept": "text/calendar,*/*",
        })
        with urllib.request.urlopen(req, timeout=12) as resp:
            text = resp.read().decode("utf-8", "replace")
        if "BEGIN:VCALENDAR" not in text:
            return "", "not a calendar (check the secret iCal link)"
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(cache, "w", encoding="utf-8") as fh:
            fh.write(text)
        return text, ""
    except Exception as exc:  # noqa: BLE001
        try:
            with open(cache, encoding="utf-8", errors="replace") as fh:
                return fh.read(), "offline (cached)"
        except OSError:
            return "", str(exc)[:60]


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


def parse_events(text, into=None):
    events = [] if into is None else into
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
            if base == "DTSTART":
                params = {}
                if ";" in key:
                    for p in key.split(";")[1:]:
                        if "=" in p:
                            pk, pv = p.split("=", 1)
                            params[pk.upper()] = pv
                cur["start"] = parse_dt(val, params)
            elif base == "DTEND":
                cur["end"] = parse_dt(val, {})
            elif base == "SUMMARY":
                cur["summary"] = val.replace("\\,", ",").replace("\\n", " ").strip()
            elif base == "RRULE":
                cur["rrule"] = parse_rrule(val)
    return events


def occurrences(ev, start, end):
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
        try:
            until = datetime.datetime.strptime(rrule["UNTIL"].rstrip("Z")[:8], "%Y%m%d").date()
        except ValueError:
            until = None
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
            hit = cur.weekday() in [wdmap[d] for d in byday if d in wdmap] if byday else cur.weekday() == base.weekday()
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


def add_months(d, n):
    y = d.year + (d.month - 1 + n) // 12
    m = (d.month - 1 + n) % 12 + 1
    return d.replace(year=y, month=m, day=min(d.day, calendar.monthrange(y, m)[1]))


def events_for(events, day):
    items = []
    for ev in events:
        for d, tm in occurrences(ev, day, day):
            if d == day:
                items.append((tm or "all-day", ev.get("summary", "(no title)")))
    items.sort()
    return items


def load_calendars(conf, force=False):
    """Return (events, errors) for all configured URLs."""
    events, errors = [], []
    for url in conf.get("ICS_URLS", []):
        text, err = fetch_ics(url, force)
        if text:
            parse_events(text, into=events)
        if err:
            errors.append(err)
    return events, errors


def next_event(events):
    now = datetime.datetime.now()
    for offset in range(0, 14):
        day = now.date() + datetime.timedelta(days=offset)
        for tm, summary in events_for(events, day):
            if tm.strip() == "all-day":
                when = datetime.datetime.combine(day, datetime.time(0, 0))
            else:
                try:
                    hh, mm = tm.split(":")
                    when = datetime.datetime.combine(day, datetime.time(int(hh), int(mm)))
                except ValueError:
                    when = datetime.datetime.combine(day, datetime.time(0, 0))
            if when < now:
                continue
            if offset == 0:
                mins = int((when - now).total_seconds() // 60)
                return ("in %dm %s" % (mins, summary)) if mins < 600 else ("%s %s" % (tm.strip(), summary))
            return "%s %s %s" % (day.strftime("%a"), "" if tm.strip() == "all-day" else tm.strip(), summary)
    return ""


# ── drawing ──────────────────────────────────────────────────────────────────
def put(stdscr, y, x, text, attr=0):
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

    grid_w = 4 + 7 * 3
    left = max(0, (w - grid_w) // 2)

    title = "%s %d" % (MONTHS[m - 1], y)
    put(stdscr, 1, left, title, curses.A_BOLD)
    put(stdscr, 1, left + len(title) + 2, "Week %d" % sel.isocalendar()[1], curses.A_DIM)

    put(stdscr, 3, left, "    " + "".join("%-3s" % d for d in WD), curses.A_DIM)
    row = 4
    for week in cal_month(y, m):
        put(stdscr, row, left, "w%02d " % week[0].isocalendar()[1], curses.A_DIM)
        for i, day in enumerate(week):
            attr = curses.A_NORMAL
            if day.month != m or i >= 5:
                attr |= curses.A_DIM
            if day == today:
                attr |= curses.A_UNDERLINE | curses.A_BOLD
            if day == sel:
                attr = curses.A_REVERSE | curses.A_BOLD
            put(stdscr, row, left + 4 + i * 3, "%3d" % day.day, attr)
        row += 1

    footer_row = h - 2
    msg_row = h - 3
    ev_top = row + 1
    avail = footer_row - ev_top - 1
    if avail > 0:
        conf = state["conf"]
        if not conf.get("ICS_URLS"):
            put(stdscr, ev_top, left, "No calendar synced — press s to add a Google iCal URL.", curses.A_DIM)
        else:
            items = events_for(state["events"], sel)
            ncal = len(conf["ICS_URLS"])
            head = "Events — %s  (%d calendar%s)" % (sel.strftime("%a %d %b %Y"), ncal, "" if ncal == 1 else "s")
            put(stdscr, ev_top, left, head, curses.A_BOLD)
            if state.get("errors"):
                put(stdscr, ev_top + 1, left, "  sync: %s" % state["errors"][0], curses.A_DIM)
            elif items:
                for i, (tm, summary) in enumerate(items[:max(0, avail - 1)]):
                    put(stdscr, ev_top + 1 + i, left, "  %-8s %s" % (tm, summary))
            else:
                put(stdscr, ev_top + 1, left, "  (none today)", curses.A_DIM)

    if state.get("msg"):
        put(stdscr, msg_row, left, state["msg"], curses.A_DIM)
    footer = "</> day  PgUp/Dn month  t today  s add ical  x clear  o Google  q quit"
    put(stdscr, footer_row, max(0, (w - len(footer)) // 2), footer, curses.A_DIM)
    stdscr.refresh()


def cal_month(y, m):
    return calendar.Calendar(0).monthdatescalendar(y, m)


def prompt(stdscr, label):
    """Read a line of arbitrary length (scrolls horizontally), Enter=accept."""
    h, w = stdscr.getmaxyx()
    y = h - 3
    buf = ""
    curses.noecho()
    curses.curs_set(1)
    while True:
        avail = max(1, w - 4 - len(label))
        start = max(0, len(buf) - avail + 1)
        vis = buf[start:]
        put(stdscr, y, 2, " " * max(0, w - 3))
        put(stdscr, y, 3, label + vis, curses.A_BOLD)
        try:
            stdscr.move(y, min(w - 2, 3 + len(label) + len(vis)))
        except curses.error:
            pass
        stdscr.refresh()
        try:
            ch = stdscr.getch()
        except curses.error:
            break
        if ch in (10, 13, curses.KEY_ENTER):
            break
        if ch == 27:
            buf = ""
            break
        if ch in (curses.KEY_BACKSPACE, 127, 8):
            buf = buf[:-1]
        elif ch == curses.KEY_RESIZE:
            continue
        elif 32 <= ch < 127:
            buf += chr(ch)
    curses.curs_set(0)
    return buf


def reload(state, force=False):
    state["events"], state["errors"] = load_calendars(state["conf"], force)


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


def main(stdscr):
    curses.curs_set(0)
    try:
        curses.use_default_colors()
    except curses.error:
        pass
    today = datetime.date.today()
    state = {"sel": today, "conf": read_conf(), "msg": "", "events": [], "errors": []}
    reload(state)

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
            url = prompt(stdscr, "iCal URL: ")
            if url.strip():
                if url.strip() not in state["conf"]["ICS_URLS"]:
                    state["conf"]["ICS_URLS"].append(url.strip())
                write_conf(state["conf"])
                reload(state, force=True)
                n = len(state["events"])
                state["msg"] = "Saved — %d event%s loaded%s" % (
                    n, "" if n == 1 else "s",
                    "" if not state["errors"] else " (" + state["errors"][0] + ")")
        elif ch == ord("x"):
            state["conf"]["ICS_URLS"] = []
            write_conf(state["conf"])
            state["events"], state["errors"] = [], []
            state["msg"] = "Calendar sync cleared."
        state["sel"] = sel


if __name__ == "__main__":
    import sys
    if "--next" in sys.argv:
        _conf = read_conf()
        _evs, _ = load_calendars(_conf)
        _line = next_event(_evs) if _evs else ""
        if _line:
            print(_line)
        sys.exit(0)
    curses.wrapper(main)
