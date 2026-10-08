#!/usr/bin/env bash
# Standalone, local-user-only migration of known NIRUPI desktop files.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/common.sh"
MODE=plan
usage(){ echo 'Usage: ./migrate-desktop.sh [--plan|--apply|--rollback RUN_ID]'; }
while (($#)); do
 case "$1" in
 --plan) MODE=plan;; --apply) MODE=apply;;
 --rollback) MODE=rollback; shift; (($#)) || die 'Missing run ID'; RUN=$1;;
 -h|--help) usage; exit 0;; *) die "Unknown argument: $1";; esac
 shift
done
[[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] || die 'Run locally, not over SSH'
[[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]] || die 'Use a local text TTY, not a graphical session'
[[ ! -L $STATE ]] || die 'State directory is a symlink'
[[ ! -e $STATE || -d $STATE ]] || die 'State path is not a directory'
# Strictly scoped to NIRUPI desktop paths; no deletion of packages, home data,
# SSH, Fish, GPG, networking, display managers or global system binaries.
paths=(
 "$HOME/.config/suckless/dwm/config.h"
 "$HOME/.Xresources"
 "$HOME/.xinitrc"
 "$HOME/.local/bin/nirupi-session"
 "$HOME/.local/share/rofi/themes/Black-Metal.rasi"
)
for app in dwm dmenu st dmenu_run dmenu_path stest; do paths+=("$HOME/.local/bin/$app"); done
for app in kitty dunst picom rofi alacritty gtk-3.0 cmus; do
 if [[ -d $ROOT/vendor/noir/config/$app ]]; then
  while IFS= read -r -d '' f; do
   paths+=("$HOME/.config/$app/${f#"$ROOT/vendor/noir/config/$app/"}")
  done < <(find "$ROOT/vendor/noir/config/$app" -type f -print0)
 fi
done
for f in "$ROOT"/vendor/noir/local/bin/*; do
 [[ -f $f ]] && paths+=("$HOME/.local/bin/${f##*/}")
done
# Do not touch symlinked parent directories, including ~/.config and ~/.local.
check_parents(){
 local p="$1" d
 d="$(dirname "$p")"
 while [[ $d != / && $d != "$HOME" ]]; do
  [[ ! -L $d && ( ! -e $d || -d $d ) ]] || die "Unsafe parent: $d"
  d="$(dirname "$d")"
 done
}
if [[ $MODE == rollback ]]; then
 [[ $RUN =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die 'Invalid run ID'
 base="$STATE/migrations/$RUN"
 [[ -d $base && ! -L $base && -f $base/manifest.nul && ! -L $base/manifest.nul ]] || die 'No valid migration backup'
 [[ -t 0 ]] || die 'Rollback requires TTY'
 echo "Rollback will restore files from $base; files installed after migration may be replaced."
 read -r -p 'Type ROLLBACK to proceed: ' ans
 [[ $ans == ROLLBACK ]] || die 'Cancelled'
 while IFS= read -r -d '' path; do
  [[ $path == "$HOME/"* ]] || die "Unsafe rollback path: $path"
  allowed=0
  for expected in "${paths[@]}"; do [[ $path != "$expected" ]] || allowed=1; done
  [[ $allowed == 1 ]] || die "Rollback path outside migration scope: $path"
  check_parents "$path"
  [[ ! -d $path || -L $path ]] || die "Refusing to replace directory: $path"
  backup="$base/files${path#"$HOME"}"
  [[ -e $backup || -L $backup ]] || die "Backup missing: $backup"
  mkdir -p "$(dirname "$path")"
  rm -f -- "$path"
  cp -a -- "$backup" "$path"
  printf 'RESTORED %s\n' "$path"
 done < "$base/manifest.nul"
 echo 'User files restored. Package/system changes and newly created files are NOT rolled back.'
 exit 0
fi
printf 'NIRUPI desktop migration (%s) — selected existing paths:\n' "$MODE"
found=0
for path in "${paths[@]}"; do
 check_parents "$path"
 if [[ -e $path || -L $path ]]; then
  [[ ! -d $path || -L $path ]] || die "Directory collision: $path"
  printf '  %s\n' "$path"; ((found+=1))
 fi
done
printf 'Existing files: %d\n' "$found"
if [[ $MODE == plan ]]; then
 echo 'Read-only plan. Migration excludes Fish, SSH, user documents and system files.'
 exit 0
fi
[[ -t 0 ]] || die 'Migration requires interactive TTY'
read -r -p 'Type REPLACE DESKTOP to archive these files and clear their paths: ' ans
[[ $ans == 'REPLACE DESKTOP' ]] || die 'Cancelled'
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
base="$STATE/migrations/$RUN_ID"
mkdir -m 0700 -p "$base/files"
chmod 0700 "$base"
: > "$base/manifest.nul"
# Copy all existing targets first; a failed copy must not delete any original.
for path in "${paths[@]}"; do
 if [[ -e $path || -L $path ]]; then
  backup="$base/files${path#"$HOME"}"
  mkdir -p "$(dirname "$backup")"
  cp -a -- "$path" "$backup"
  # Verify regular-file copies before any originals are removed.
  if [[ -f $path && ! -L $path ]]; then
   cmp -s -- "$path" "$backup" || die "Backup verification failed: $path"
  elif [[ -L $path ]]; then
   [[ $(readlink -- "$path") == "$(readlink -- "$backup")" ]] || die "Symlink backup verification failed: $path"
  fi
  printf '%s\0' "$path" >> "$base/manifest.nul"
 fi
done
# Remove only after the full backup is complete.
while IFS= read -r -d '' path; do
 check_parents "$path"
 rm -f -- "$path"
done < "$base/manifest.nul"
printf 'Migration complete. Backup ID: %s\n' "$RUN_ID"
printf 'Rollback: bash ./migrate-desktop.sh --rollback %s\n' "$RUN_ID"
echo 'Now run install.sh --doctor, --plan and --apply from the same local TTY.'
