#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for f in "$ROOT/install.sh" "$ROOT/runtime-session.sh" "$ROOT"/lib/*.sh; do bash -n "$f"; done
for app in dwm dmenu st slock; do test -f "$ROOT/vendor/suckless/$app/Makefile"; done
for file in "$ROOT/vendor/sddm/Main.qml" "$ROOT/vendor/noir/local/bin/dwm-status.sh" "$ROOT/runtime-xinitrc" "$ROOT/vendor/suckless/dwm/config.h"; do test -f "$file"; done
bash -n "$ROOT/runtime/nirupi-updates"
for f in "$ROOT"/vendor/noir/local/bin/*.sh; do bash -n "$f"; done
printf 'PASS: Bash syntax and critical bundled assets\n'
if [[ $(id -u) -ne 0 ]]; then
 before="$(find "${XDG_STATE_HOME:-$HOME/.local/state}/nirupi" -type f 2>/dev/null | wc -l || true)"
 "$ROOT/install.sh" --plan > /dev/null
 after="$(find "${XDG_STATE_HOME:-$HOME/.local/state}/nirupi" -type f 2>/dev/null | wc -l || true)"
 [[ $before == "$after" ]]
 printf 'PASS: plan is read-only\n'
fi

# Alpha regression guards.
grep -q '0.2.0-alpha.32' "$ROOT/VERSION"
grep -q 'Exec=/usr/local/bin/nirupi-session' "$ROOT/lib/install.sh"
grep -Fq 'pacman -Syu --needed' "$ROOT/lib/packages.sh" && ! grep -Fq 'xbps-install -Su' "$ROOT/lib/packages.sh"
for distro in arch cachyos debian void; do grep -q "$distro" "$ROOT/lib/packages.sh"; done
printf 'PASS: alpha.31 regression guards\n'

# Prevent a regression where a one-line numeric count was counted as one update.
! grep -Fq '"$CHECKUPDATES" 2>/dev/null | wc -l' "$ROOT/vendor/noir/local/bin/dwm-status.sh"
for helper in clip-menu.sh clip-save.sh screenshot-select.sh screenshot-browser.sh webapp-dmenu.sh; do
  grep -q "$helper" "$ROOT/lib/install.sh"
done
printf 'PASS: status count and helper deployment regression guards\n'

"$ROOT/tests/preflight.sh" --assets

"$ROOT/tests/hardware-audit.sh" >/dev/null
printf "PASS: read-only hardware audit\n"

"$ROOT/tests/updates.sh"

# Refuse to take ownership of a symlink managed by another tool.
grep -q 'Refusing to replace unmanaged symlink' "$ROOT/lib/common.sh"
printf 'PASS: unmanaged symlink protection present\n'

if [[ $(id -u) -ne 0 ]]; then "$ROOT/tests/file-ops.sh"; fi

# Build staging must clean up on all normal and error exits.
grep -Fq "trap 'rm -rf -- \"\$stage_root\"' EXIT" "$ROOT/lib/install.sh"
grep -Fq 'install_desktop() (' "$ROOT/lib/install.sh"
printf 'PASS: build-stage cleanup guard\n'

"$ROOT/tests/dwm-config.sh"

"$ROOT/tests/desktop-integration.sh"

"$ROOT/tests/build-output.sh"

"$ROOT/tests/session-runtime.sh"

"$ROOT/tests/system-session.sh"

"$ROOT/tests/noir-consistency.sh"

"$ROOT/tests/rofi-integration.sh"

"$ROOT/tests/shortcut-dependencies.sh"

"$ROOT/tests/config-preservation.sh"

"$ROOT/tests/managed-upgrade.sh"

"$ROOT/tests/managed-configs.sh"

"$ROOT/tests/dwm-build-config.sh"

"$ROOT/tests/preflight-collisions.sh"

"$ROOT/tests/install-readiness.sh"

"$ROOT/tests/migration.sh"

"$ROOT/tests/bare-metal-guards.sh"
