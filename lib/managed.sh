#!/usr/bin/env bash
# Called only after sourcing lib/common.sh; STATE and BACKUP_DIR must exist.
# Every deployment is a non-destructive three-way merge between:
#   base   = the checksum NIRUPI recorded the last time it wrote the file
#   ours   = the checksum of the file currently on disk
#   theirs = the checksum of the bundled source we are installing
# Managed + unmodified files are upgraded in place. Modified or untracked
# files are preserved and a sibling "<file>.nirupi-new" proposal is written.

# Replace the recorded checksum for one identifier in a TSV manifest.
_manifest_record(){
  local manifest="$1" name="$2" hash="$3" tmp
  [[ ! -L $manifest ]] || die "Refusing symlink manifest: $manifest"
  mkdir -p -- "$STATE"
  tmp="$(mktemp "$STATE/.manifest.XXXXXXXX")"
  if [[ -f $manifest ]]; then
    awk -F '\t' -v name="$name" '$1 != name' "$manifest" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  fi
  printf '%s\t%s\n' "$name" "$hash" >> "$tmp"
  mv -f -- "$tmp" "$manifest"
}

_manifest_hash(){
  local manifest="$1" name="$2"
  [[ -f $manifest && ! -L $manifest ]] || return 0
  awk -F '\t' -v name="$name" '$1 == name {print $2}' "$manifest" | tail -n 1
}

# Offer the bundled version without overwriting a user-owned file.
_propose_config(){
  local src="$1" dest="$2" mode="$3" proposal="${dest}.nirupi-new"
  if [[ -e $proposal || -L $proposal ]]; then
    [[ -f $proposal && ! -L $proposal ]] || return 0
    cmp -s -- "$src" "$proposal" && return 0
  fi
  put_file "$src" "$proposal" "$mode"
  warn "Preserved local changes; new version available at $proposal"
}

# Only upgrade a helper when its current content matches the last recorded
# NIRUPI checksum. Untracked and user-modified files are never overwritten.
managed_helper_install() {
 local name="$1" src="$2" dest="$3" manifest="$STATE/managed-helpers.tsv"
 local previous='' current='' new_hash=''
 [[ -f $src && ! -L $src ]] || die "Missing or symlinked helper source: $src"
 [[ $name =~ ^[a-zA-Z0-9._-]+$ ]] || die "Invalid helper name: $name"
 if [[ -e $dest || -L $dest ]]; then
  if [[ -L $dest || ! -f $dest ]]; then
   warn "Preserving non-regular helper: $dest"; return 0
  fi
  previous="$(_manifest_hash "$manifest" "$name")"
  current="$(sha256sum -- "$dest" | cut -d ' ' -f 1)"
  if [[ ${NIRUPI_REFRESH:-0} == 1 ]]; then
   # Explicit adopt: refresh an older/untracked NIRUPI helper (backup kept).
   warn "Refreshing NIRUPI helper (backup kept): $dest"
  elif [[ -z $previous || $current != "$previous" ]]; then
   warn "Preserving modified or untracked helper: $dest"; return 0
  fi
 fi
 new_hash="$(sha256sum -- "$src" | cut -d ' ' -f 1)"
 put_file "$src" "$dest" 0755
 _manifest_record "$manifest" "$name" "$new_hash"
}

# For configuration assets, preserve unknown or user-edited files. A recorded
# checksum is an ownership assertion only if the destination still matches it.
managed_config_install() {
 local name="$1" src="$2" dest="$3" mode="${4:-0644}"
 local manifest="$STATE/managed-configs.tsv" previous='' current='' new_hash=''
 [[ -f $src && ! -L $src ]] || die "Missing or symlinked config source: $src"
 [[ $name =~ ^[a-zA-Z0-9._/-]+$ && $name != /* && $name != *..* ]] || die "Invalid managed config identifier: $name"
 [[ $mode == 0644 || $mode == 0755 ]] || die "Invalid config mode: $mode"
 new_hash="$(sha256sum -- "$src" | cut -d ' ' -f 1)"
 if [[ -e $dest || -L $dest ]]; then
  if [[ -L $dest || ! -f $dest ]]; then
   warn "Preserving non-regular config: $dest"; return 0
  fi
  previous="$(_manifest_hash "$manifest" "$name")"
  current="$(sha256sum -- "$dest" | cut -d ' ' -f 1)"
  if [[ $current == "$new_hash" ]]; then
   # Already current: refresh the manifest and repair a lost permission bit.
   put_file "$src" "$dest" "$mode"
   _manifest_record "$manifest" "$name" "$new_hash"
   return 0
  fi
  if [[ -n $previous && $current == "$previous" ]]; then
   # Managed and unmodified: safe in-place upgrade.
   put_file "$src" "$dest" "$mode"
   _manifest_record "$manifest" "$name" "$new_hash"
   return 0
  fi
  # User-modified or untracked: keep the file, offer the bundled version.
  _propose_config "$src" "$dest" "$mode"
  return 0
 fi
 [[ ! -L $manifest ]] || die "Refusing symlink manifest: $manifest"
 put_file "$src" "$dest" "$mode"
 _manifest_record "$manifest" "$name" "$new_hash"
}
