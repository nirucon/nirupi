#!/usr/bin/env bash
# NIRU clipboard transforms. Applies a chosen transform to the clipboard text.
# Menu via rofi/dmenu; clipboard via wl-clipboard (Wayland) or xclip (X11).
set -Eeuo pipefail

read_clip(){
  if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
  elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --output
  fi
}
write_clip(){
  if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy >/dev/null 2>&1; then wl-copy
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -i
  elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input
  else cat >/dev/null; fi
}
menu(){
  if command -v rofi >/dev/null 2>&1; then rofi -dmenu -i -p 'Clipboard'
  elif command -v dmenu >/dev/null 2>&1; then dmenu -i -p 'Clipboard'
  else cat; fi
}
note(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI Clipboard "$1" >/dev/null 2>&1 || :; }

text="$(read_clip 2>/dev/null || true)"
[[ -n $text ]] || { note 'Clipboard is empty'; exit 0; }

opts='UPPERCASE
lowercase
Title Case
Trim whitespace
Collapse blank lines
Sort lines
Unique lines
Reverse lines
Base64 encode
Base64 decode
URL encode
URL decode
JSON pretty
Strip ANSI
Count lines/words/chars'
choice="$(printf '%s\n' "$opts" | menu || true)"
[[ -n $choice ]] || exit 0

out="$text"
case "$choice" in
  'UPPERCASE')            out="$(printf '%s' "$text" | tr '[:lower:]' '[:upper:]')";;
  'lowercase')            out="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')";;
  'Title Case')           out="$(printf '%s' "$text" | sed 's/\b\(.\)/\u\1/g')";;
  'Trim whitespace')      out="$(printf '%s' "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')";;
  'Collapse blank lines') out="$(printf '%s\n' "$text" | cat -s)";;
  'Sort lines')           out="$(printf '%s\n' "$text" | sort)";;
  'Unique lines')         out="$(printf '%s\n' "$text" | awk '!seen[$0]++')";;
  'Reverse lines')        out="$(printf '%s\n' "$text" | tac 2>/dev/null || printf '%s\n' "$text" | tail -r)";;
  'Base64 encode')        out="$(printf '%s' "$text" | base64 -w0 2>/dev/null || printf '%s' "$text" | base64)";;
  'Base64 decode')        out="$(printf '%s' "$text" | base64 -d 2>/dev/null || printf '%s' "$text" | base64 --decode)";;
  'URL encode')           out="$(printf '%s' "$text" | python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=""))' 2>/dev/null || printf '%s' "$text")";;
  'URL decode')           out="$(printf '%s' "$text" | python3 -c 'import sys,urllib.parse;print(urllib.parse.unquote(sys.stdin.read()))' 2>/dev/null || printf '%s' "$text")";;
  'JSON pretty')          out="$(printf '%s' "$text" | python3 -c 'import sys,json;print(json.dumps(json.loads(sys.stdin.read()),indent=2,ensure_ascii=False))' 2>/dev/null || printf '%s' "$text")";;
  'Strip ANSI')           out="$(printf '%s' "$text" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g')";;
  'Count lines/words/chars')
    lines="$(printf '%s\n' "$text" | wc -l)"; words="$(printf '%s' "$text" | wc -w)"; chars="$(printf '%s' "$text" | wc -c)"
    note "$lines lines, $words words, $chars chars"; exit 0;;
esac

printf '%s' "$out" | write_clip
note "$choice applied"
