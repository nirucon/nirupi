#!/usr/bin/env bash
# NIRU: mount/unmount removable drives with udisks2 (no daemon of our own).
# Bound to the control center and the keybinding palette.
set -Eeuo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "USB" "$1" >/dev/null 2>&1; else printf 'USB: %s\n' "$1"; fi; }
menu(){ if have rofi; then rofi -dmenu -i -p 'USB'; elif have dmenu; then dmenu -i -p 'USB'; else head -n1; fi; }

have lsblk   || { notify 'lsblk missing'; exit 1; }
have udisksctl || { notify 'udisksctl missing (install udisks2)'; exit 1; }

raw="$(lsblk -Pno NAME,RM,FSTYPE,LABEL,SIZE,MOUNTPOINT 2>/dev/null | grep 'RM="1"' || true)"
[[ -n $raw ]] || { notify 'No removable devices found'; exit 0; }

names=(); rows=()
while IFS= read -r line; do
  [[ -n $line ]] || continue
  line=" $line"
  name="$(sed -n 's/.* NAME="\([^"]*\)".*/\1/p' <<<"$line")"
  fstype="$(sed -n 's/.* FSTYPE="\([^"]*\)".*/\1/p' <<<"$line")"
  label="$(sed -n 's/.* LABEL="\([^"]*\)".*/\1/p' <<<"$line")"
  size="$(sed -n 's/.* SIZE="\([^"]*\)".*/\1/p' <<<"$line")"
  mp="$(sed -n 's/.* MOUNTPOINT="\([^"]*\)".*/\1/p' <<<"$line")"
  [[ -n $name && -n $fstype ]] || continue   # only formatted partitions
  where="not mounted"; [[ -n $mp ]] && where="mounted: $mp"
  names+=("$name")
  rows+=("$name  ${label:-(no label)}  $size  [$where]")
done <<<"$raw"

if ((${#rows[@]} == 0)); then notify 'No mountable partitions found'; exit 0; fi

sel="$(printf '%s\n' "${rows[@]}" | menu)" || exit 0
[[ -n $sel ]] || exit 0
name="${sel%% *}"
dev="/dev/$name"

mp="$(lsblk -rno MOUNTPOINT "/dev/$name" 2>/dev/null | head -n1)"
if [[ -n $mp ]]; then
  udisksctl unmount -b "$dev" >/dev/null 2>&1 && notify "Unmounted $dev" || notify "Could not unmount $dev"
else
  udisksctl mount -b "$dev" >/dev/null 2>&1 && notify "Mounted $dev" || notify "Could not mount $dev"
fi
