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
 # Update the manifest only after put_file has successfully deployed the helper.
 put_file "$src" "$dest" 0755
 mkdir -p -- "$STATE"
 tmp="$(mktemp "$STATE/.managed-helpers.XXXXXXXX")"
 if [[ -f $manifest ]]; then
  awk -F '\t' -v name="$name" '$1 != name' "$manifest" > "$tmp" || { rm -f -- "$tmp"; return 1; }
 fi
 printf '%s\t%s\n' "$name" "$new_hash" >> "$tmp"
 mv -f -- "$tmp" "$manifest"
}

# For configuration assets, preserve unknown or user-edited files. A recorded
# checksum is an ownership assertion only if the destination still matches it.
managed_config_install() {
 local name="$1" src="$2" dest="$3" mode="${4:-0644}"
 local manifest="$STATE/managed-configs.tsv" previous='' current='' new_hash='' tmp=''
 [[ -f $src && ! -L $src ]] || die "Missing or symlinked config source: $src"
 [[ $name =~ ^[a-zA-Z0-9._/-]+$ && $name != /* && $name != *..* ]] || die "Invalid managed config identifier: $name"
 [[ $mode == 0644 || $mode == 0755 ]] || die "Invalid config mode: $mode"
 if [[ -e $dest || -L $dest ]]; then
  if [[ -L $dest || ! -f $dest ]]; then
   warn "Preserving non-regular config: $dest"; return 0
  fi
  if [[ -f $manifest && ! -L $manifest ]]; then
   previous="$(awk -F '\t' -v name="$name" '$1 == name {print $2}' "$manifest" | tail -n 1)"
  fi
  current="$(sha256sum -- "$dest" | cut -d ' ' -f 1)"
  if [[ -z $previous || $current != "$previous" ]]; then
   warn "Preserving modified or untracked config: $dest"; return 0
  fi
 fi
 # Never follow a symlink in the state path for a privileged manifest write.
 [[ ! -L $manifest ]] || die "Refusing symlink manifest: $manifest"
 new_hash="$(sha256sum -- "$src" | cut -d ' ' -f 1)"
 put_file "$src" "$dest" "$mode"
 mkdir -p -- "$STATE"
 tmp="$(mktemp "$STATE/.managed-configs.XXXXXXXX")"
 if [[ -f $manifest ]]; then
  awk -F '\t' -v name="$name" '$1 != name' "$manifest" > "$tmp" || { rm -f -- "$tmp"; return 1; }
 fi
 printf '%s\t%s\n' "$name" "$new_hash" >> "$tmp"
 mv -f -- "$tmp" "$manifest"
}
