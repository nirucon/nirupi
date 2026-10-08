#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export NIRUPI_SYSTEM_LAUNCHER="$TMP/nirupi-session"
export NIRUPI_SYSTEM_DESKTOP="$TMP/nirupi-dwm.desktop"
eval "$(sed -n '/^check_system_session_conflicts(){/,/^}/p' "$ROOT/lib/install.sh")"
die(){ printf '%s\n' "$*" >&2; exit 1; }
check_system_session_conflicts
printf '#!/bin/sh\nexec "${HOME}/.local/bin/nirupi-session"\n' > "$NIRUPI_SYSTEM_LAUNCHER"
printf '[Desktop Entry]\nExec=/usr/local/bin/nirupi-session\n' > "$NIRUPI_SYSTEM_DESKTOP"
check_system_session_conflicts
printf '#!/bin/sh\nexec /bin/false\n' > "$NIRUPI_SYSTEM_LAUNCHER"
if (check_system_session_conflicts) >/dev/null 2>&1; then echo 'FAIL: foreign launcher accepted' >&2; exit 1; fi
printf '#!/bin/sh\nexec "${HOME}/.local/bin/nirupi-session"\n' > "$NIRUPI_SYSTEM_LAUNCHER"
printf '[Desktop Entry]\nExec=/bin/false\n' > "$NIRUPI_SYSTEM_DESKTOP"
if (check_system_session_conflicts) >/dev/null 2>&1; then echo 'FAIL: foreign desktop entry accepted' >&2; exit 1; fi
rm "$NIRUPI_SYSTEM_DESKTOP"
ln -s /bin/true "$NIRUPI_SYSTEM_DESKTOP"
if (check_system_session_conflicts) >/dev/null 2>&1; then echo 'FAIL: symlink desktop entry accepted' >&2; exit 1; fi
echo 'PASS: system session collision tests'
