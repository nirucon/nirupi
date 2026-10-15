#!/usr/bin/env bash
# Status-bar pop-up: disk usage panel (per real mount, with bars).
set -Eeuo pipefail
{
  printf '@title Disk\n'
  printf '@sub %s\n' "$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null)"
  printf '@accent blue\n'
  df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR>1 {
    pct=$5; sub(/%/,"",pct);
    printf "@bar %s\n", pct;
    printf "@row %s|%s / %s\n", $6, $3, $2;
  }'
} | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Disk >/dev/null 2>&1 || true
