#!/usr/bin/env bash
# NIRU: rewrite the current selection in place with the AI agent. The rewritten
# text replaces the selection in the focused field/editor (via xdotool type).
# Bound to Super+Ctrl+r.
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Agent "$1" >/dev/null 2>&1 || :; }

sel(){
  local s=""
  have xclip && s="$(xclip -selection primary -o 2>/dev/null || true)"
  [[ -n $s ]] || { have xclip && s="$(xclip -selection clipboard -o 2>/dev/null || true)"; }
  printf '%s' "$s"
}

text="$(sel)"
[[ -n ${text//[[:space:]]/} ]] || { note 'Select some text first'; exit 0; }
have opencode || { note 'opencode not found'; exit 1; }
have xdotool || { note 'xdotool required'; exit 1; }

note 'Rewriting…'
prompt="Rewrite the following text so it is clear and correct. Keep the language and any formatting. Reply with ONLY the rewritten text — no quotes, no explanation."
res="$(timeout 90 opencode run "$prompt"$'\n\n'"$text" 2>/dev/null || true)"
[[ -n ${res//[[:space:]]/} ]] || { note 'No rewrite produced'; exit 0; }

# Typing overwrites the current selection in most X11 editors and fields.
if xdotool type --clearmodifiers --delay 1 -- "$res" 2>/dev/null; then
  note 'Rewritten'
else
  printf '%s' "$res" | { have xclip && xclip -selection clipboard -i || cat >/dev/null; }
  note 'Could not type it; copied to clipboard'
fi
