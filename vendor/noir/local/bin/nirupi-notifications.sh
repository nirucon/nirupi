#!/usr/bin/env bash
# NIRU: browse the dunst notification history in rofi; selecting one re-pops it.
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
have dunstctl || { printf 'dunstctl not found\n' >&2; exit 1; }

rows="$(dunstctl history 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
for e in d.get("data", []):
    if not e: continue
    n = e[0]
    s = (n.get("summary") or "").replace("\n", " ")
    b = (n.get("body") or "").replace("\n", " ")[:80]
    print("%s\t%s — %s" % (n.get("id", ""), s, b))
' 2>/dev/null || true)"

[[ -n $rows ]] || { printf '(no notifications in history)\n'; exit 0; }

sel="$(printf '%s\n' "$rows" | { if have rofi; then rofi -dmenu -i -p 'Notifications'; elif have dmenu; then dmenu -i -p 'Notifications'; else cat; fi; } || true)"
[[ -n $sel ]] || exit 0
id="$(printf '%s' "$sel" | awk -F'\t' '{print $1}')"
[[ -n $id ]] && dunstctl history-pop "$id" >/dev/null 2>&1 || true
