#!/usr/bin/env bash
# NIRU: send the current X11 selection (or clipboard) to the AI agent.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Agent "$1" >/dev/null 2>&1 || :; }

selection(){
  local s=""
  have xclip && s="$(xclip -selection primary -o 2>/dev/null || true)"
  [[ -n $s ]] || { have xclip && s="$(xclip -selection clipboard -o 2>/dev/null || true)"; }
  [[ -n $s ]] || { have wl-paste && s="$(wl-paste --no-newline 2>/dev/null || true)"; }
  printf '%s' "$s"
}

sel="$(selection)"
[[ -n ${sel//[[:space:]]/} ]] || { note 'Select some text first (or copy it)'; exit 0; }

printf '%s' "$sel" | exec "$HOME/.local/bin/nirupi-agent-ask.sh"
