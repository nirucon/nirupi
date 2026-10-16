#!/usr/bin/env bash
# Void runit provisioning: base services, SDDM activation and PipeWire start.
# Also guards that the Debian/Arch (systemd) code paths stay untouched.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INS="$ROOT/lib/install.sh"; SESSION="$ROOT/runtime-session.sh"
fail(){ echo "FAIL $*" >&2; exit 1; }

# --- Void: runit service helper and base services ---------------------------
grep -q '^enable_void_service(){' "$INS" || fail 'enable_void_service helper missing'
for svc in dbus elogind polkitd tailscaled bluetoothd NetworkManager; do
  grep -Eq "for svc in .*\b$svc\b" "$INS" || fail "Void base service not enabled: $svc"
done
grep -q 'enable_void_service "$svc" /var/service' "$INS" || fail 'Void services not routed via the helper'

# --- Void: SDDM activation through runit -------------------------------------
grep -q 'enable_void_service sddm /var/service' "$INS" || fail 'Void SDDM unit not enabled'
grep -q 'DISTRO == void' "$INS" || fail 'Void branch missing'

# --- Void: display-manager conflict detection without systemctl --------------
grep -q '/var/service/\$dm' "$INS" || fail 'Void DM conflict check missing'

# --- Void: the session starts PipeWire (Void ships no runit service for it) ---
grep -q 'pipewire' "$SESSION" || fail 'PipeWire start missing from the session'
grep -q 'SESSION_DISTRO" = void' "$SESSION" || fail 'PipeWire start is not Void-gated'
# PipeWire must be started from the session, never through systemd on Void.
grep -q 'systemctl --user start pipewire' "$SESSION" && fail 'session must not start systemd PipeWire'
# It must set XDG_RUNTIME_DIR and wait for the native socket instead of racing.
grep -q 'XDG_RUNTIME_DIR' "$SESSION" || fail 'XDG_RUNTIME_DIR not handled'
grep -q 'pipewire-0' "$SESSION" || fail 'no wait for the PipeWire socket'
# WirePlumber / pipewire-pulse are enabled via the handbook's config drop-ins.
grep -q '10-wireplumber.conf' "$SESSION" || fail 'wireplumber drop-in missing'
grep -q '20-pipewire-pulse.conf' "$SESSION" || fail 'pipewire-pulse drop-in missing'
# PipeWire must NOT be killed with the session (avoids a restart race/gap).
grep -q 'PWPIDS' "$SESSION" && fail 'PipeWire is still torn down with the session'

# --- Guard: Debian/Arch (systemd) behaviour unchanged ------------------------
grep -q 'sudo systemctl enable sddm.service' "$INS" || fail 'systemd SDDM enable removed'
grep -q 'systemctl is-enabled --quiet "\$dm.service"' "$INS" || fail 'systemd DM conflict check removed'
grep -q 'systemctl enable --now "\$unit.service"' "$INS" || fail 'systemd service enabling removed'
grep -q 'systemctl suspend' "$SESSION" || fail 'systemd suspend path removed'

# --- Behavioural: enable_void_service is idempotent and safe -----------------
# Run the isolated helper against a user-writable fake runsvdir. Skipped off
# Void, where /etc/sv does not exist.
if [[ -e /etc/sv/dbus ]]; then
  eval "$(sed -n '/^enable_void_service(){/,/^}/p' "$INS")"
  log(){ :; }
  sudo(){ "$@"; }   # the temp root is user-writable: no real privilege needed
  TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
  enable_void_service does-not-exist "$TMP" && fail 'missing unit accepted'
  enable_void_service dbus "$TMP" || fail 'existing unit not enabled'
  [[ -L "$TMP/dbus" ]] || fail 'no symlink created for the unit'
  enable_void_service dbus "$TMP" || fail 'second enable not idempotent'
else
  echo 'SKIP: /etc/sv absent (Void-only behavioural check)'
fi

echo 'PASS: Void runit services, SDDM and PipeWire; Debian/Arch paths intact'
