#!/usr/bin/env bash
# Called only after sourcing lib/common.sh; STATE and BACKUP_DIR must exist.
# Only upgrade a helper when its current content matches the last recorded
# NIRUPI checksum. Untracked and user-modified files are never overwritten.
managed_helper_install() {
 local name="$1" src="$2" dest="$3" manifest="$STATE/managed-helpers.tsv"
 local previous='' current='' tmp='' new_hash=''
 [[ -f $src && ! -L $src ]] || die "Missing or symlinked helper source: $src"
 [[ $name =~ ^[a-zA-Z0-9._-]+$ ]] || die "Invalid helper name: $name"
 if [[ -e $dest || -L $dest ]]; then
  if [[ -L $dest || ! -f $dest ]]; then
   warn "Preserving non-regular helper: $dest"; return 0
  fi
  if [[ -f $manifest ]]; then
   previous="$(awk -F '\t' -v name="$name" '$1 == name {print $2}' "$manifest" | tail -n 1)"
  fi
  current="$(sha256sum -- "$dest" | cut -d ' ' -f 1)"
  if [[ -z $previous || $current != "$previous" ]]; then
   warn "Preserving modified or untracked helper: $dest"; return 0
  fi
 fi
 new_hash="$(sha256sum -- "$src" | cut -d ' ' -f 1)"
 put_file "$src" "$dest" 0755
 mkdir -p -- "$STATE"
 tmp="$(mktemp "$STATE/.managed-helpers.XXXXXXXX")"
 if [[ -f $manifest ]]; then
  awk -F '\t' -v name="$name" '$1 != name' "$manifest" > "$tmp" || { rm -f -- "$tmp"; return 1; }
 fi
 printf '%s\t%s\n' "$name" "$new_hash" >> "$tmp"
 mv -f -- "$tmp" "$manifest"
}
