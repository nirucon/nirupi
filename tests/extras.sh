#!/usr/bin/env bash
# Quality-of-life extras: capture, AI selection/screen/command, emoji, clipboard
# transforms, audio picker, per-workspace wallpapers, SSH picker, reload/edit,
# completions, help/man page.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bin="$ROOT/vendor/noir/local/bin"

for s in nirupi-capture.sh nirupi-agent-selection.sh nirupi-agent-ask.sh \
         nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-emoji.sh \
         nirupi-clip-transform.sh nirupi-audio.sh nirupi-wallpaper.sh \
         nirupi-tag-wallpaper.sh nirupi-reload.sh nirupi-edit.sh nirupi-ssh.sh; do
  [[ -f "$bin/$s" ]] || { echo "FAIL missing $s" >&2; exit 1; }
  bash -n "$bin/$s" || { echo "FAIL syntax $s" >&2; exit 1; }
  grep -q "$s" "$ROOT/lib/install.sh" || { echo "FAIL $s not deployed" >&2; exit 1; }
done

# dwm wiring: per-workspace wallpaper hook + new bindings + schema bump.
DWM="$ROOT/vendor/suckless/dwm"
grep -q 'runwallhook' "$DWM/dwm.c" || { echo 'FAIL dwm tag hook missing' >&2; exit 1; }
grep -qE 'runwallhook\(\);' "$DWM/dwm.c" || { echo 'FAIL dwm hook not called' >&2; exit 1; }
grep -q 'nirupi-tag-wallpaper.sh' "$DWM/dwm.c" || { echo 'FAIL dwm hook command missing' >&2; exit 1; }
for cmd in capturecmd agentselectioncmd askscreencmd askcommandcmd sshcmd; do
  grep -q "$cmd\[\]" "$DWM/config.h" || { echo "FAIL $cmd missing" >&2; exit 1; }
done
grep -q 'nirupi-agent-screen.sh' "$DWM/config.h" || { echo 'FAIL screen binding missing' >&2; exit 1; }
grep -q 'nirupi-ask-command.sh' "$DWM/config.h" || { echo 'FAIL AI-command binding missing' >&2; exit 1; }
grep -q 'nirupi-ssh.sh' "$DWM/config.h" || { echo 'FAIL ssh binding missing' >&2; exit 1; }
grep -q 'NIRUPI_CONFIG_VERSION 5' "$DWM/config.h" || { echo 'FAIL schema not bumped' >&2; exit 1; }

# Control center + keybinding palette entries.
for e in 'Wallpapers per workspace: toggle' 'Audio output' 'SSH / host…' 'Reload desktop…' 'Edit config…' 'Ask agent about screen…' 'AI command…'; do
  grep -qF "$e" "$bin/nirupi-menu.sh" || { echo "FAIL menu missing: $e" >&2; exit 1; }
done
for e in nirupi-emoji.sh nirupi-agent-selection.sh nirupi-capture.sh nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-ssh.sh nirupi-reload.sh nirupi-edit.sh; do
  grep -q "$e" "$bin/nirupi-keys.sh" || { echo "FAIL palette missing: $e" >&2; exit 1; }
done

# Completions, man page, wallpaper example.
[[ -f "$ROOT/vendor/noir/config/fish/completions/nirupi.fish" ]] || { echo 'FAIL fish completion' >&2; exit 1; }
[[ -f "$ROOT/vendor/noir/local/share/bash-completion/completions/nirupi" ]] || { echo 'FAIL bash completion' >&2; exit 1; }
[[ -f "$ROOT/runtime/nirupi.1" ]] || { echo 'FAIL man page' >&2; exit 1; }
[[ -f "$ROOT/runtime/wallpapers.conf.example" ]] || { echo 'FAIL wallpaper example' >&2; exit 1; }

# nirupi help + edit --list.
out="$(bash "$ROOT/runtime/nirupi" help 2>/dev/null)"
grep -q 'nirupi ssh' <<< "$out" || { echo 'FAIL help ssh' >&2; exit 1; }
grep -q 'nirupi edit' <<< "$out" || { echo 'FAIL help edit' >&2; exit 1; }
grep -q 'nirupi reload' <<< "$out" || { echo 'FAIL help reload' >&2; exit 1; }
bash "$bin/nirupi-edit.sh" --list | grep -q '^  status ' || { echo 'FAIL edit --list' >&2; exit 1; }
[[ "$(bash "$bin/nirupi-edit.sh" --path dwm)" == */suckless/dwm/config.h ]] || { echo 'FAIL edit --path' >&2; exit 1; }

echo 'PASS: extras (capture, AI selection/screen/command, emoji, clipboard, audio, wallpapers, ssh, reload/edit, completions, help)'
