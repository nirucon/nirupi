#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/vendor/noir/local/bin/dwm-status.sh"
bash -n "$SCRIPT"
for fn in provider_cached get_cpu get_bluetooth get_temp_high get_mic get_dnd get_recording get_nextcloud icon_mic icon_dnd icon_rec icon_cloud; do
  grep -q "^${fn}() {" "$SCRIPT" || { echo "FAIL missing function: $fn" >&2; exit 1; }
done
grep -q '0f0f10' "$ROOT/runtime-session.sh" || { echo 'FAIL session noir bg' >&2; exit 1; }
grep -q 'xresources.noir' "$ROOT/runtime-session.sh" || { echo 'FAIL session xresources noir' >&2; exit 1; }

# Functional smoke: render one status line with network/weather/updates disabled.
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/home/.local/bin" "$TMP/home/.config/nirupi"
cat > "$TMP/home/.local/bin/xsetroot" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$TMP/bar.txt"
EOF
chmod +x "$TMP/home/.local/bin/xsetroot"
cat > "$TMP/home/.config/nirupi/status.conf" <<'EOF'
SHOW_WEATHER=0
SHOW_UPDATES=0
SHOW_NETWORK=0
SHOW_MEDIA=0
SHOW_NOW_PLAYING=0
SHOW_NEXTCLOUD=0
EOF
HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" XDG_CONFIG_HOME="$TMP/home/.config" timeout 5 bash "$SCRIPT" 2>"$TMP/err" || true
[[ -s "$TMP/bar.txt" ]] || { echo "FAIL status bar produced no output" >&2; cat "$TMP/err" >&2; exit 1; }
line="$(head -n1 "$TMP/bar.txt")"
[[ "$line" == *"["* && "$line" == *"]"* ]] || { echo "FAIL malformed bar: $line" >&2; exit 1; }
# Noir default must be monochrome (no status2d colour codes).
[[ "$line" != *'^c#'* ]] || { echo "FAIL Noir bar contains colour codes" >&2; exit 1; }
echo 'PASS: status bar providers, temp, DND/mic/recording and Nextcloud segments'
