#!/usr/bin/env bash
# Back up NIRUPI-managed user configuration into a single tarball, and
# optionally schedule it (systemd user timer, else cron).
# Destination: ~/Nextcloud/nirupi-backups when a Nextcloud folder exists,
# otherwise ~/.local/state/nirupi/backups/.
#   nirupi backup                 # back up now
#   nirupi backup --schedule      # enable a weekly backup timer
#   nirupi backup --unschedule    # disable it
set -Eeuo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nirupi"

backup_now(){
  local STAMP nextcloud dest archive
  STAMP="$(date +%Y%m%d-%H%M%S)"
  nextcloud=""
  local d
  for d in "$HOME/Nextcloud" "$HOME/nextcloud" "$HOME/Nextcloud2"; do
    [[ -d "$d" ]] && { nextcloud="$d"; break; }
  done
  if [[ -n "$nextcloud" ]]; then dest="$nextcloud/nirupi-backups"; else dest="$STATE/backups"; fi
  mkdir -p "$dest"
  archive="$dest/nirupi-config-$STAMP.tar.gz"

  local -a paths=()
  local p
  for p in \
    "$HOME/.config/nirupi" \
    "$HOME/.config/suckless" \
    "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/tmux" \
    "$HOME/.config/lazygit" "$HOME/.config/micro" "$HOME/.config/aerc" \
    "$HOME/.config/dunst" "$HOME/.config/picom" "$HOME/.config/rofi" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.Xresources" "$HOME/.xinitrc" "$HOME/.gtkrc-2.0"; do
    [[ -e "$p" ]] && paths+=("${p#"$HOME"/}")
  done

  [[ ${#paths[@]} -gt 0 ]] || { echo 'Nothing to back up' >&2; exit 0; }
  tar -czf "$archive" -C "$HOME" "${paths[@]}"
  printf 'Backup written: %s\n' "$archive"
  command -v notify-send >/dev/null 2>&1 && notify-send "NIRUPI" "Backup complete: $archive"
}

schedule(){
  local self="$HOME/.local/bin/nirupi-backup.sh"
  [[ -x $self ]] || self="$0"
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
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
  if command -v crontab >/dev/null 2>&1; then
    local line="0 12 * * 0 $self >/dev/null 2>&1"
    ( crontab -l 2>/dev/null | grep -v 'nirupi-backup.sh'; printf '%s\n' "$line" ) | crontab -
    printf 'Scheduled weekly backup via cron\n'
    return 0
  fi
  printf 'No scheduler available (systemd user or crontab); backup not scheduled\n' >&2
  exit 1
}

unschedule(){
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now nirupi-backup.timer 2>/dev/null || :
    rm -f "$HOME/.config/systemd/user/nirupi-backup.timer" "$HOME/.config/systemd/user/nirupi-backup.service"
    systemctl --user daemon-reload 2>/dev/null || :
  fi
  if command -v crontab >/dev/null 2>&1; then
    ( crontab -l 2>/dev/null | grep -v 'nirupi-backup.sh' ) | crontab - 2>/dev/null || :
  fi
  printf 'Scheduled backup disabled\n'
}

case "${1:-}" in
  ''|--now) backup_now;;
  --schedule) schedule;;
  --unschedule|--disable) unschedule;;
  -h|--help) printf 'nirupi backup [--schedule|--unschedule]\n';;
  *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2;;
esac
