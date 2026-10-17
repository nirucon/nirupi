#!/usr/bin/env bash
# Back up NIRUPI-managed user configuration into a single tarball, and
# optionally schedule it (systemd user timer, else cron).
# Destination: ~/Nextcloud/nirupi-backups when a Nextcloud folder exists,
# otherwise ~/.local/state/nirupi/backups/.
#
#   nirupi backup                 # back up now
#   nirupi backup --list          # list archives
#   nirupi backup --verify FILE   # check an archive
#   nirupi backup --restore FILE  # restore into $HOME (backup first)
#   nirupi backup --schedule      # enable a weekly backup timer
#   nirupi backup --unschedule    # disable it
#
# Optional encryption: set NIRUPI_BACKUP_AGE_RECIPIENT to an age public key
# (age is then required). Restore with NIRUPI_BACKUP_AGE_KEY pointing at the
# private key.
set -Eeuo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"
KEEP="${NIRUPI_BACKUP_KEEP:-14}"
[[ $KEEP =~ ^[0-9]+$ ]] || KEEP=14

have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ have notify-send && notify-send -a NIRUPI "$@" >/dev/null 2>&1 || :; }

backup_dest(){
  local d
  for d in "$HOME/Nextcloud" "$HOME/nextcloud" "$HOME/Nextcloud2"; do
    [[ -d "$d" ]] && { printf '%s/nirupi-backups' "$d"; return 0; }
  done
  printf '%s/backups' "$STATE"
}

backup_paths(){
  PATHS=()
  local p
  for p in \
    "$HOME/.config/nirupi" \
    "$HOME/.config/suckless" \
    "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/tmux" \
    "$HOME/.config/lazygit" "$HOME/.config/micro" "$HOME/.config/aerc" \
    "$HOME/.config/dunst" "$HOME/.config/picom" "$HOME/.config/rofi" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.Xresources" "$HOME/.xinitrc" "$HOME/.gtkrc-2.0"; do
    [[ -e "$p" ]] && PATHS+=("${p#"$HOME"/}")
  done
  return 0
}

prune_backups(){
  local dest="$1" old
  mapfile -t old < <(find "$dest" -maxdepth 1 -type f \( -name 'nirupi-config-*.tar.gz' -o -name 'nirupi-config-*.tar.gz.age' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | awk -v keep="$KEEP" 'NR>keep {sub(/^[^ ]+ /, ""); print}')
  ((${#old[@]})) || return 0
  rm -f -- "${old[@]}"
}

backup_now(){
  local stamp dest archive
  stamp="$(date +%Y%m%d-%H%M%S)-$$"
  dest="$(backup_dest)"
  mkdir -p "$dest"
  archive="$dest/nirupi-config-$stamp.tar.gz"
  backup_paths
  [[ ${#PATHS[@]} -gt 0 ]] || { echo 'Nothing to back up' >&2; return 0; }
  if [[ -n ${NIRUPI_BACKUP_AGE_RECIPIENT:-} ]]; then
    have age || { echo 'NIRUPI_BACKUP_AGE_RECIPIENT is set but age is missing' >&2; exit 1; }
    archive="$archive.age"
    tar -czf - -C "$HOME" "${PATHS[@]}" | age -r "$NIRUPI_BACKUP_AGE_RECIPIENT" -o "$archive"
  else
    tar -czf "$archive" -C "$HOME" "${PATHS[@]}"
  fi
  printf 'Backup written: %s\n' "$archive"
  prune_backups "$dest"
  notify "Backup complete: $archive"
}

# Reject absolute paths and path traversal before extracting.
check_archive_paths(){
  local file="$1" tmp p
  tmp="$(mktemp)"
  if [[ $file == *.age ]]; then
    have age || { rm -f -- "$tmp"; echo 'age is required to read this archive' >&2; return 1; }
    [[ -n ${NIRUPI_BACKUP_AGE_KEY:-} ]] || { rm -f -- "$tmp"; echo 'Set NIRUPI_BACKUP_AGE_KEY for an encrypted archive' >&2; return 1; }
    age -d -i "$NIRUPI_BACKUP_AGE_KEY" "$file" | tar -tzf - > "$tmp" || { rm -f -- "$tmp"; return 1; }
  else
    tar -tzf "$file" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  fi
  while IFS= read -r p; do
    if [[ $p == /* || $p == *..* ]]; then
      echo "Unsafe archive path: $p" >&2
      rm -f -- "$tmp"
      return 1
    fi
  done < "$tmp"
  rm -f -- "$tmp"
  return 0
}

extract_archive(){
  local file="$1"
  [[ -f $file && ! -L $file ]] || { echo "Not a regular file: $file" >&2; return 1; }
  check_archive_paths "$file" || return 1
  if [[ $file == *.age ]]; then
    age -d -i "$NIRUPI_BACKUP_AGE_KEY" "$file" | tar -xzf - -C "$HOME"
  else
    tar -xzf "$file" -C "$HOME"
  fi
}

restore_archive(){
  local file="$1" yes="${2:-0}" answer
  [[ -n $file ]] || { echo 'Usage: nirupi backup --restore FILE [--yes]' >&2; exit 2; }
  [[ -f $file ]] || { echo "Archive not found: $file" >&2; exit 1; }
  if [[ $yes != 1 ]]; then
    [[ -t 0 ]] || { echo 'Restore requires an interactive terminal (or --yes)' >&2; exit 1; }
    echo 'This restores NIRUPI-managed user configuration into $HOME.'
    echo 'The current configuration is backed up first.'
    printf 'Type RESTORE to continue: '
    read -r answer
    [[ $answer == RESTORE ]] || { echo 'Cancelled'; exit 1; }
  fi
  backup_now >/dev/null
  extract_archive "$file"
  echo "Restored from $file"
  notify "Configuration restored: $file"
}

verify_archive(){
  local file="$1"
  [[ -f $file ]] || { echo "Archive not found: $file" >&2; exit 1; }
  check_archive_paths "$file" || exit 1
  if [[ $file == *.age ]]; then
    age -d -i "$NIRUPI_BACKUP_AGE_KEY" "$file" | tar -tzf - >/dev/null
  else
    tar -tzf "$file" >/dev/null
  fi
  echo "OK: $file"
}

list_archives(){
  local dest; dest="$(backup_dest)"
  [[ -d $dest ]] || { echo 'No backup directory yet'; return 0; }
  find "$dest" -maxdepth 1 -type f \( -name 'nirupi-config-*.tar.gz' -o -name 'nirupi-config-*.tar.gz.age' \) -printf '%TY-%Tm-%Td %TH:%TM  %10s  %p\n' 2>/dev/null | sort -r
}

schedule(){
  local self="$HOME/.local/bin/nirupi-backup.sh"
  [[ -x $self ]] || self="$0"
  if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
    local unit="$HOME/.config/systemd/user"
    mkdir -p "$unit"
    cat > "$unit/nirupi-backup.service" <<EOF
[Unit]
Description=NIRUPI configuration backup
[Service]
Type=oneshot
ExecStart=$self
EOF
    cat > "$unit/nirupi-backup.timer" <<'EOF'
[Unit]
Description=Weekly NIRUPI configuration backup
[Timer]
OnCalendar=weekly
Persistent=true
[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now nirupi-backup.timer
    printf 'Scheduled weekly backup via systemd user timer (nirupi-backup.timer)\n'
    return 0
  fi
  if have crontab; then
    local line="0 12 * * 0 $self >/dev/null 2>&1"
    ( crontab -l 2>/dev/null | grep -v 'nirupi-backup.sh'; printf '%s\n' "$line" ) | crontab -
    printf 'Scheduled weekly backup via cron\n'
    return 0
  fi
  printf 'No scheduler available (systemd user or crontab); backup not scheduled\n' >&2
  exit 1
}

unschedule(){
  if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now nirupi-backup.timer 2>/dev/null || :
    rm -f "$HOME/.config/systemd/user/nirupi-backup.timer" "$HOME/.config/systemd/user/nirupi-backup.service"
    systemctl --user daemon-reload 2>/dev/null || :
  fi
  if have crontab; then
    ( crontab -l 2>/dev/null | grep -v 'nirupi-backup.sh' ) | crontab - 2>/dev/null || :
  fi
  printf 'Scheduled backup disabled\n'
}

case "${1:-}" in
  ''|--now) backup_now;;
  --list) list_archives;;
  --verify) shift; verify_archive "${1:-}";;
  --restore)
   shift || true
   yes=0
   if [[ ${1:-} == --yes ]]; then yes=1; shift || true; fi
   file="${1:-}"
   [[ ${2:-} == --yes ]] && yes=1
   restore_archive "$file" "$yes";;
  --schedule) schedule;;
  --unschedule|--disable) unschedule;;
  -h|--help) printf 'nirupi backup [--list|--verify FILE|--restore FILE|--schedule|--unschedule]\n';;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2;;
esac
