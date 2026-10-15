#!/usr/bin/env bash
# NIRU audio output picker: choose the default PipeWire sink via wpctl.
set -Eeuo pipefail

note(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI Audio "$1" >/dev/null 2>&1 || :; }
command -v wpctl >/dev/null 2>&1 || { note 'wpctl (PipeWire) not found'; exit 1; }

emit(){
  local raw l def id name
  raw="$(wpctl status 2>/dev/null | awk '/Sinks:/{f=1;next} f&&/Sources:/{exit} f')"
  while IFS= read -r l; do
    [[ $l == *'.'* ]] || continue
    def=""; [[ $l == *'*'* ]] && def="  (default)"
    id="$(sed -E 's/^[^0-9]*([0-9]+)\..*/\1/' <<<"$l")"
    name="$(sed -E 's/^.*[0-9]+\. *//' <<<"$l" | sed -E 's/ *\[[^]]*\].*$//; s/ *$//')"
    [[ -n $id && -n $name ]] && printf '%s  %s%s\n' "$id" "$name" "$def"
  done <<<"$raw"
}

choice="$(emit | { if command -v rofi >/dev/null 2>&1; then rofi -dmenu -i -p 'Audio output'; elif command -v dmenu >/dev/null 2>&1; then dmenu -i -p 'Audio output'; else cat; fi; } || true)"
[[ -n $choice ]] || exit 0
id="$(awk '{print $1}' <<<"$choice")"
[[ $id =~ ^[0-9]+$ ]] || exit 0
if wpctl set-default "$id" 2>/dev/null; then note "Output set to ${choice#"$id"  }"; else note 'Could not change output'; fi
