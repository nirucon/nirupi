#!/usr/bin/env bash
# Safe, distro-independent statusbar upgrade from a NIRUPI source checkout.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/vendor/noir/local/bin/dwm-status.sh"
DEST="$HOME/.local/bin/dwm-status.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"
MANIFEST="$STATE/managed-helpers.tsv"
BACKUPS="$STATE/statusbar-backups"
MODE="${1:---check}"
usage() { printf 'Usage: %s [--check|--apply|--adopt]\n' "$0"; }
[[ $# -le 1 ]] || { usage; exit 2; }
case "$MODE" in --check|--apply|--adopt) ;; *) usage; exit 2;; esac
for path in "$HOME/.local" "$HOME/.local/bin" "$STATE" "$MANIFEST" "$BACKUPS" "$DEST"; do
  [[ ! -L "$path" ]] || { printf 'REFUSE symlink: %s\n' "$path" >&2; exit 1; }
done
[[ -f "$SRC" && ! -L "$SRC" ]] || { echo 'Missing safe source' >&2; exit 1; }
bash -n "$SRC"
grep -q '^render_cached_now_playing()' "$SRC" || { echo 'Source lacks smooth-scroll renderer' >&2; exit 1; }
[[ ! -e "$DEST" || -f "$DEST" ]] || { echo 'Unsafe destination' >&2; exit 1; }
[[ ! -e "$MANIFEST" || -f "$MANIFEST" ]] || { echo 'Unsafe manifest' >&2; exit 1; }
new="$(sha256sum "$SRC" | cut -d' ' -f1)"
old=''
[[ -f "$DEST" ]] && old="$(sha256sum "$DEST" | cut -d' ' -f1)"
recorded=''
[[ -f "$MANIFEST" ]] && recorded="$(awk -F '\t' '$1=="dwm-status.sh" {print $2}' "$MANIFEST" | tail -n1)"
if [[ "$old" == "$new" ]]; then
  printf 'OK already current (%s)\n' "$new"
  exit 0
fi
if [[ -n "$old" && "$old" != "$recorded" && "$MODE" != --adopt ]]; then
  printf 'REFUSE untracked or modified statusbar; use --adopt to back up and explicitly replace it.\n' >&2
  exit 1
fi
if [[ "$MODE" == --check ]]; then
  printf 'UPDATE available: %s -> %s\n' "${old:-not-installed}" "$new"
  exit 0
fi
mkdir -p "$HOME/.local/bin" "$STATE" "$BACKUPS"
backup=''
if [[ -f "$DEST" ]]; then
  backup="$(mktemp "$BACKUPS/dwm-status.XXXXXXXX.bak")"
  cp -p -- "$DEST" "$backup"
fi
tmp="$(mktemp "$HOME/.local/bin/.dwm-status.XXXXXXXX")"
manifest_tmp=''
trap 'rm -f -- "$tmp" "${manifest_tmp:-}"' EXIT
install -m 0755 -- "$SRC" "$tmp"
mv -f -- "$tmp" "$DEST"
manifest_tmp="$(mktemp "$STATE/.managed-helpers.XXXXXXXX")"
if [[ -f "$MANIFEST" ]]; then
  awk -F '\t' '$1!="dwm-status.sh"' "$MANIFEST" > "$manifest_tmp"
fi
printf 'dwm-status.sh\t%s\n' "$new" >> "$manifest_tmp"
mv -f -- "$manifest_tmp" "$MANIFEST"
printf 'INSTALLED %s\nBackup: %s\n' "$new" "${backup:-none}"
printf 'Restart the DWM session to activate the new script; running processes are not killed.\n'
