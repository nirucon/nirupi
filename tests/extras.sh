#!/usr/bin/env bash
# Quality-of-life extras: capture, AI selection, emoji, clipboard transforms,
# audio picker, per-workspace wallpapers, completions, help/man page.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bin="$ROOT/vendor/noir/local/bin"

for s in nirupi-capture.sh nirupi-agent-selection.sh nirupi-emoji.sh \
         nirupi-clip-transform.sh nirupi-audio.sh nirupi-wallpaper.sh \
         nirupi-tag-wallpaper.sh; do
  [[ -f "$bin/$s" ]] || { echo "FAIL missing $s" >&2; exit 1; }
  bash -n "$bin/$s" || { echo "FAIL syntax $s" >&2; exit 1; }
  grep -q "$s" "$ROOT/lib/install.sh" || { echo "FAIL $s not deployed" >&2; exit 1; }
done

# dwm wiring: per-workspace wallpaper hook + new bindings + schema bump.
DWM="$ROOT/vendor/suckless/dwm"
grep -q 'runwallhook' "$DWM/dwm.c" || { echo 'FAIL dwm tag hook missing' >&2; exit 1; }
grep -qE 'runwallhook\(\);' "$DWM/dwm.c" || { echo 'FAIL dwm hook not called' >&2; exit 1; }
grep -q 'nirupi-tag-wallpaper.sh' "$DWM/dwm.c" || { echo 'FAIL dwm hook command missing' >&2; exit 1; }
grep -q 'nirupi-capture.sh' "$DWM/config.h" || { echo 'FAIL capture binding missing' >&2; exit 1; }
grep -q 'nirupi-agent-selection.sh' "$DWM/config.h" || { echo 'FAIL agent-selection binding missing' >&2; exit 1; }
grep -q 'NIRUPI_CONFIG_VERSION 4' "$DWM/config.h" || { echo 'FAIL schema not bumped' >&2; exit 1; }

# Control center + keybinding palette entries.
grep -q 'Wallpapers per workspace: toggle' "$bin/nirupi-menu.sh" || { echo 'FAIL menu wallpaper toggle' >&2; exit 1; }
grep -q 'Audio output' "$bin/nirupi-menu.sh" || { echo 'FAIL menu audio' >&2; exit 1; }
grep -q 'nirupi-emoji.sh' "$bin/nirupi-keys.sh" || { echo 'FAIL palette emoji' >&2; exit 1; }
grep -q 'nirupi-agent-selection.sh' "$bin/nirupi-keys.sh" || { echo 'FAIL palette agent' >&2; exit 1; }
grep -q 'nirupi-capture.sh' "$bin/nirupi-keys.sh" || { echo 'FAIL palette capture' >&2; exit 1; }

# Completions, man page, wallpaper example.
[[ -f "$ROOT/vendor/noir/config/fish/completions/nirupi.fish" ]] || { echo 'FAIL fish completion' >&2; exit 1; }
[[ -f "$ROOT/vendor/noir/local/share/bash-completion/completions/nirupi" ]] || { echo 'FAIL bash completion' >&2; exit 1; }
[[ -f "$ROOT/runtime/nirupi.1" ]] || { echo 'FAIL man page' >&2; exit 1; }
[[ -f "$ROOT/runtime/wallpapers.conf.example" ]] || { echo 'FAIL wallpaper example' >&2; exit 1; }

# Help works, including a topic.
bash "$ROOT/runtime/nirupi" help 2>/dev/null | grep -q 'nirupi theme' || { echo 'FAIL nirupi help' >&2; exit 1; }
bash "$ROOT/runtime/nirupi" help wallpaper 2>/dev/null | grep -q 'per-tag' || { echo 'FAIL nirupi help wallpaper' >&2; exit 1; }

echo 'PASS: extras (capture, AI selection, emoji, clipboard, audio, per-workspace wallpaper, completions, help)'
