#!/usr/bin/env bash
# NIRUPI migration engine.
# Provides installed-state tracking, legacy layout detection, safe timestamped
# archival of foreign binaries/symlinks and a read-only migration report.
# Sourced only after lib/common.sh (needs STATE, VERSION, HOME, log/warn/die).
# Never deletes user data: configuration files are merged in place by
# managed_config_install (see lib/managed.sh); only binary collisions are
# archived, and always with a verifiable backup first.

# Bump when the on-disk layout or manifest semantics change.
NIRUPI_SCHEMA=2

# Applications NIRUPI owns and links into ~/.local/bin.
NIRUPI_MANAGED_APPS=(dwm dmenu st dmenu_run dmenu_path stest slstatus)

# ---------------------------------------------------------------------------
# Installed state
# ---------------------------------------------------------------------------
installed_env_path(){ printf '%s' "$STATE/installed.env"; }

read_installed_state(){
  local key="$1" file; file="$(installed_env_path)"
  [[ -f $file && ! -L $file ]] || return 0
  awk -F= -v k="$key" '$1==k{sub(/^[^=]*=/,"");print;exit}' "$file"
}

write_installed_state(){
  local file tmp
  file="$(installed_env_path)"
  [[ ! -L $file ]] || { warn "Refusing symlinked state file: $file"; return 0; }
  mkdir -p -- "$STATE"
  tmp="$(mktemp "$STATE/.installed.XXXXXXXX")"
  {
    printf 'NIRUPI_VERSION=%s\n' "$VERSION"
    printf 'NIRUPI_SCHEMA=%s\n' "$NIRUPI_SCHEMA"
    printf 'NIRUPI_DISTRO=%s\n' "${DISTRO:-unknown}"
    printf 'NIRUPI_SESSION=%s\n' "${SESSION:-unknown}"
    printf 'NIRUPI_INSTALLED_AT=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  } > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$file"
}

# True when $1 is a symlink pointing into the NIRUPI install tree.
is_nirupi_link(){
  local link="$1" target
  [[ -L $link ]] || return 1
  target="$(readlink -- "$link" 2>/dev/null || :)"
  [[ $target == "$HOME/.local/lib/nirupi/"* ]]
}

# ---------------------------------------------------------------------------
# Legacy detection (read-only)
# ---------------------------------------------------------------------------
# Emits tab-separated records: kind<TAB>path<TAB>detail
detect_legacy_layout(){
  local app path bin
  for app in "${NIRUPI_MANAGED_APPS[@]}"; do
    path="$HOME/.local/bin/$app"
    if [[ -L $path ]]; then
      is_nirupi_link "$path" || printf 'binary\t%s\tforeign-symlink\n' "$path"
    elif [[ -e $path ]]; then
      printf 'binary\t%s\tforeign-file\n' "$path"
    fi
  done
  for bin in /usr/local/bin/dwm /usr/local/bin/dmenu /usr/local/bin/st /usr/local/bin/slstatus; do
    [[ -e $bin || -L $bin ]] && printf 'system-binary\t%s\tlegacy\n' "$bin"
  done
  for path in \
    "$HOME/.config/suckless/dwm/config.h" \
    "$HOME/.config/suckless/st/config.h" \
    "$HOME/.config/suckless/dmenu/config.h" \
    "$HOME/.config/suckless/dwm" \
    "$HOME/.dwm" \
    "$HOME/.config/dwm" \
    "$HOME/.config/xinitrc.d" \
    "$HOME/.xinitrc" \
    "$HOME/.Xresources" \
    "$HOME/.config/fish/config.fish"; do
    [[ -e $path || -L $path ]] && printf 'config\t%s\tlegacy\n' "$path"
  done
}

# Read-only migration report for the requested phase (plan/diff/apply).
migration_report(){
  local kind path detail legacy_count=0
  printf 'NIRUPI migration report\n'
  printf '  installed version: %s\n' "${VERSION:-unknown}"
  local iv; iv="$(read_installed_state NIRUPI_VERSION)"
  printf '  previously installed: %s\n' "${iv:-none}"
  local is; is="$(read_installed_state NIRUPI_SCHEMA)"
  printf '  installed schema: %s (current %s)\n' "${is:-none}" "$NIRUPI_SCHEMA"
  printf '  distributions: %s\n' "${DISTRO:-unknown}"
  printf '\n  Legacy layout detected:\n'
  while IFS=$'\t' read -r kind path detail; do
    [[ -n $kind ]] || continue
    legacy_count=$((legacy_count + 1))
    case "$kind" in
      binary*) printf '    ARCHIVE   %-9s %s\n' "$detail" "$path";;
      system-binary) printf '    NOTE      %-9s %s (left untouched)\n' "$detail" "$path";;
      config) printf '    MERGE     %-9s %s\n' "$detail" "$path";;
    esac
  done < <(detect_legacy_layout)
  (( legacy_count )) || printf '    (none)\n'
  printf '\n  Binary collisions are archived under %s/legacy/<run>/ before linking.\n' "$STATE"
  printf '  Configuration files are never deleted; modified/untracked files get a\n'
  printf '  sibling *.nirupi-new proposal instead of being overwritten.\n'
}

# ---------------------------------------------------------------------------
# Legacy archival (write) — only used for binary collisions
# ---------------------------------------------------------------------------
legacy_root(){ printf '%s' "$STATE/legacy"; }

archive_legacy_path(){
  local run_id="$1" path="$2" base dest rel
  [[ $path == "$HOME"/* ]] || die "Refusing to archive path outside HOME: $path"
  [[ $run_id =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]] || die "Invalid migration run id: $run_id"
  base="$(legacy_root)/$run_id"
  rel="${path#"$HOME"/}"
  dest="$base/$rel"
  [[ ! -L $dest ]] || die "Unsafe archive target: $dest"
  mkdir -p -- "$(dirname "$dest")"
  [[ ! -e $dest && ! -L $dest ]] || dest="$dest.$(date +%s).$$"
  cp -a -- "$path" "$dest"
  if [[ -L $path ]]; then
    [[ -L $dest ]] || die "Archive verification failed for symlink: $path"
  elif [[ -f $path ]]; then
    if command -v cmp >/dev/null 2>&1; then
      cmp -s -- "$path" "$dest" || die "Archive verification failed: $path"
    elif [[ "$(wc -c < "$path")" != "$(wc -c < "$dest")" ]]; then
      die "Archive verification failed (size mismatch): $path"
    fi
  fi
  printf '%s\t%s\n' "$path" "$dest" >> "$base/manifest.tsv"
  rm -f -- "$path"
  log "Archived legacy binary: $path -> $dest"
}

# Archive every foreign binary that would block a NIRUPI symlink.
resolve_binary_conflicts(){
  local run_id="$1" app path
  mkdir -p -- "$(legacy_root)/$run_id"
  : > "$(legacy_root)/$run_id/manifest.tsv"
  for app in "${NIRUPI_MANAGED_APPS[@]}"; do
    path="$HOME/.local/bin/$app"
    if [[ -L $path ]]; then
      is_nirupi_link "$path" || archive_legacy_path "$run_id" "$path"
    elif [[ -e $path ]]; then
      [[ -f $path ]] || die "Unsafe binary path (not a regular file): $path"
      archive_legacy_path "$run_id" "$path"
    fi
  done
}

# ---------------------------------------------------------------------------
# CLI entry point (used by the deployed nirupi-maintenance helper)
# ---------------------------------------------------------------------------
nirupi_migrate(){
  local sub="${1:-plan}"; shift || :
  case "$sub" in
    plan|diff)
      migration_report;;
    dwm)
      case "${1:-}" in
        --rebuild) migrate_dwm_rebuild;;
        *) die 'Usage: nirupi migrate dwm --rebuild';;
      esac;;
    *) die 'Usage: nirupi migrate {plan|diff|dwm --rebuild}';;
  esac
}
