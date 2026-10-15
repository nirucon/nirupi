#!/usr/bin/env bash
# Status-bar pop-up: disk usage per real mount.
set -Eeuo pipefail
{
  printf '%-22s %6s %6s %6s %5s\n' 'Mount' 'Size' 'Used' 'Avail' 'Use%'
  df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
    | awk 'NR>1 {printf "%-22s %6s %6s %6s %5s\n", $6, $2, $3, $4, $5}'
} | "$HOME/.local/bin/nirupi-popup.sh" 'Disk' >/dev/null 2>&1 || true
