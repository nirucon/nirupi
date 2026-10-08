#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/.config/suckless/dwm" "$TMP/.local/bin" "$TMP/.ssh"
printf 'personal dwm config\n' > "$TMP/.config/suckless/dwm/config.h"
printf 'keep ssh\n' > "$TMP/.ssh/config"
printf 'old dwm\n' > "$TMP/.local/bin/dwm"
export HOME="$TMP" XDG_STATE_HOME="$TMP/.local/state"
unset DISPLAY WAYLAND_DISPLAY SSH_CONNECTION SSH_TTY
"$ROOT/migrate-desktop.sh" --plan > "$TMP/plan"
grep -Fq "$TMP/.config/suckless/dwm/config.h" "$TMP/plan"
grep -Fq "$TMP/.local/bin/dwm" "$TMP/plan"
! grep -Fq "$TMP/.ssh/config" "$TMP/plan"
# Apply and rollback need a real TTY. `script` supplies a pseudo-terminal.
printf 'REPLACE DESKTOP\n' | script -q -e -c "bash '$ROOT/migrate-desktop.sh' --apply" "$TMP/apply.log" >/dev/null
[[ ! -e "$TMP/.config/suckless/dwm/config.h" && ! -e "$TMP/.local/bin/dwm" ]]
[[ $(cat "$TMP/.ssh/config") == 'keep ssh' ]]
RUN="$(find "$TMP/.local/state/nirupi/migrations" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | head -n1)"
[[ $RUN =~ ^[0-9]{8}-[0-9]{6}-[0-9]+$ ]]
printf 'ROLLBACK\n' | script -q -e -c "bash '$ROOT/migrate-desktop.sh' --rollback '$RUN'" "$TMP/rollback.log" >/dev/null
[[ $(cat "$TMP/.config/suckless/dwm/config.h") == 'personal dwm config' ]]
[[ $(cat "$TMP/.local/bin/dwm") == 'old dwm' ]]
[[ $(cat "$TMP/.ssh/config") == 'keep ssh' ]]
# Symlink parent must never be traversed.
mkdir -p "$TMP/foreign"
rm -rf "$TMP/.config/suckless"
ln -s "$TMP/foreign" "$TMP/.config/suckless"
if "$ROOT/migrate-desktop.sh" --plan >/dev/null 2>&1; then echo 'FAIL: symlinked parent accepted' >&2; exit 1; fi
printf 'PASS: migration plan, backup, rollback, sensitive-file exclusion, symlink refusal\n'
