#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
[[ -f "$CFG" ]]
grep -Fq 'SHCMD("$HOME/.local/bin/sleep-suspend.sh")' "$CFG"
! grep -Fq 'SHCMD("systemctl suspend")' "$CFG"
! grep -Fq 'restartcmd' "$CFG"
grep -Fq '"kitty", "--", "sh", "-c"' "$CFG"
for script in sleep-suspend.sh dwm-keybindings.sh wallrotate.sh clip-save.sh clip-menu.sh screenshot-select.sh screenshot-browser.sh; do
  test -f "$ROOT/vendor/noir/local/bin/$script"
  grep -Fq "$script" "$ROOT/lib/install.sh"
done
printf 'PASS: DWM keybinding integration checks\n'
