#!/usr/bin/env bash
# NIRU: send text (on stdin) to the AI agent with a chosen prompt.
# The answer opens in a terminal via `opencode run`. Internal helper used by
# nirupi-agent-selection.sh and nirupi-agent-screen.sh.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Agent "$1" >/dev/null 2>&1 || :; }
copy_txt(){ if have wl-copy && [[ -n ${WAYLAND_DISPLAY:-} ]]; then wl-copy; elif have xclip; then xclip -selection clipboard -i; else cat >/dev/null; fi; }

text="$(cat)"
[[ -n ${text//[[:space:]]/} ]] || { note 'Nothing to send'; exit 0; }

menu='Explain
Summarize
Translate to English
Translate to Swedish
Fix spelling & grammar
Explain this error
Refactor / clean up
Custom prompt…'
choice="$(printf '%s\n' "$menu" | { if have rofi; then rofi -dmenu -i -p 'Ask agent'; elif have dmenu; then dmenu -i -p 'Ask agent'; else cat; fi; } || true)"
[[ -n $choice ]] || exit 0

case "$choice" in
  'Explain')                pre='Explain clearly and concisely:';;
  'Summarize')              pre='Summarize the key points briefly:';;
  'Translate to English')   pre='Translate the following to English, keeping the tone:';;
  'Translate to Swedish')   pre='Översätt följande till svenska och behåll tonen:';;
  'Fix spelling & grammar') pre='Fix spelling and grammar, keep the meaning and formatting:';;
  'Explain this error')     pre='Explain what this error means and how to fix it:';;
  'Refactor / clean up')    pre='Refactor and clean this up; explain the changes:';;
  'Custom prompt…')
    pre="$( { if have rofi; then rofi -dmenu -i -p 'Prompt'; else cat; fi; } </dev/null || true)"
    [[ -n $pre ]] || exit 0;;
  *) exit 0;;
esac

prompt="$pre

$text"
printf '%s' "$prompt" | copy_txt >/dev/null 2>&1 || true
tmp="$(mktemp)"; printf '%s' "$prompt" > "$tmp"

if have opencode; then
  if have kitty; then
    exec kitty --title 'NIRU agent' -e bash -c 'opencode run "$(cat "$1")"; printf "\n"; read -r -p "Press Enter to close" _' _ "$tmp"
  fi
  opencode run "$prompt"
else
  note 'opencode not found — prompt copied to clipboard'
fi
