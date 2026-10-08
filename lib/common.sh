#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log(){ printf '[NIRUPI] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
die(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
[[ $EUID -ne 0 ]] || die 'Run as a normal user (sudo only for package/system changes)'
[[ -r /etc/os-release ]] || die 'Missing /etc/os-release'
source /etc/os-release
case "${ID:-}" in
 arch) DISTRO=arch;; cachyos) DISTRO=cachyos;; debian) DISTRO=debian;; void) DISTRO=void;; *) die "Unsupported distro: ${ID:-unknown}";;
esac
[[ $(uname -m) == x86_64 ]] || die 'Only x86_64 supported'
if [[ $DISTRO == void ]] && command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then die 'Void musl not yet supported'; fi
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"
VERSION="$(<"$ROOT/VERSION")"
require(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }
backup_file(){
 local f="$1" dest
 [[ -e $f || -L $f ]] || return 0
 [[ ! -d $f || -L $f ]] || die "Refusing directory replacement: $f"
 dest="$BACKUP_DIR$f"
 mkdir -p "$(dirname "$dest")"
 cp -a -- "$f" "$dest"
 printf '%s\n' "$f" >> "$BACKUP_DIR/manifest.txt"
}
put_file(){
 local src="$1" dest="$2" mode="${3:-0644}" tmp
 [[ -f $src ]] || die "Missing source: $src"
 [[ ! -d $dest ]] || die "Refusing directory collision: $dest"
 [[ ! -L $dest ]] || die "Refusing symlink replacement: $dest"
 if [[ -f $dest && ! -L $dest ]] && cmp -s -- "$src" "$dest"; then
  # Content equality is insufficient: a script may have lost its executable bit.
  [[ $(stat -c %a -- "$dest") == "${mode#0}" ]] && return 0
 fi
 mkdir -p "$(dirname "$dest")"
 backup_file "$dest"
 tmp="$(mktemp "$(dirname "$dest")/.nirupi.XXXXXXXX")"
 if ! install -m "$mode" -- "$src" "$tmp"; then rm -f -- "$tmp"; return 1; fi
 mv -f -- "$tmp" "$dest"
}
link_binary(){
 local source="$1" dest="$2" tmp
 [[ ! -d $dest ]] || die "Refusing directory collision: $dest"
 if [[ -L $dest ]] && [[ $(readlink -- "$dest") == "$source" ]]; then return 0; fi
 [[ ! -e $dest || -L $dest ]] || die "Refusing to replace non-NIRUPI binary: $dest"
 if [[ -L $dest ]]; then
   local old_target
   old_target="$(readlink -- "$dest")"
   [[ $old_target == "$HOME/.local/lib/nirupi/"* ]] ||
     die "Refusing to replace unmanaged symlink: $dest -> $old_target"
 fi
 backup_file "$dest"
 tmp="$(mktemp "$(dirname "$dest")/.nirupi-link.XXXXXXXX")"
 rm -f -- "$tmp"
 ln -s -- "$source" "$tmp"
 mv -f -- "$tmp" "$dest"
}
