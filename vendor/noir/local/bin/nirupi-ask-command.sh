#!/usr/bin/env bash
# NIRU: describe a task in plain language, let the agent suggest a shell
# command, review/edit it, and run it only when you press Enter.
# Nothing is executed without your explicit confirmation in the terminal.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Agent "$1" >/dev/null 2>&1 || :; }

have opencode || { note 'opencode not found'; exit 1; }

ask(){
  if have rofi; then rofi -dmenu -i -p "$1";
  elif have dmenu; then dmenu -i -p "$1";
  else cat; fi
}

want="$(ask 'What do you want to do?' </dev/null || true)"
[[ -n ${want//[[:space:]]/} ]] || exit 0

note 'Asking the agent for a command…'
sugg="$(timeout 90 opencode run \
  "You are a shell assistant. Reply with exactly ONE single-line POSIX/bash command that accomplishes the request below, on one line, with no explanation, no code fences and no leading \$ or #. Request: $want" \
  2>/dev/null || true)"

# Clean up common formatting noise.
sugg="$(printf '%s\n' "$sugg" \
  | sed -e 's/^[[:space:]]*```[a-zA-Z]*[[:space:]]*//' -e 's/```[[:space:]]*$//' \
  | sed -e 's/^[[:space:]]*[#$][[:space:]]\+//' \
  | grep -vE '^[[:space:]]*$' | head -n1)"
[[ -n $sugg ]] || { note 'No command suggested'; exit 0; }

run(){
  # Prefilled, editable shell prompt; run only on Enter.
  printf 'NIRU suggests:\n  %s\n\n' "$1"
  local final
  read -r -e -i "$1" -p 'Run (edit if needed, Enter to run, Ctrl-C to cancel): ' final || exit 0
  printf '\n'
  [[ -n ${final//[[:space:]]/} ]] || { printf 'Cancelled.\n'; exit 0; }
  eval "$final"
  printf '\n[exit %s]\n' "$?"
  read -r -p 'Press Enter to close' _ || true
}

if [[ -t 0 && -t 1 ]]; then run "$sugg"; exit 0; fi
for t in kitty alacritty st xterm; do
  have "$t" && exec "$t" -e bash -c 'printf "NIRU suggests:\n  %s\n\n" "$1"; read -r -e -i "$1" -p "Run (edit if needed, Enter to run, Ctrl-C to cancel): " final || exit 0; printf "\n"; [ -n "${final//[[:space:]]/}" ] || { printf "Cancelled.\n"; exit 0; }; eval "$final"; printf "\n[exit %s]\n" "$?"; read -r -p "Press Enter to close" _ || true' _ "$sugg"
done
printf 'Suggested command (copied):\n%s\n' "$sugg"
printf '%s' "$sugg" | { if have xclip; then xclip -selection clipboard -i; else cat >/dev/null; fi; }
note 'No terminal found — command copied to clipboard'
