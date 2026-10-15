#!/usr/bin/env bash
# Quality-of-life extras: capture, AI selection/screen/command/rewrite, emoji,
# clipboard transforms, audio picker, per-workspace wallpapers, SSH picker,
# unified launcher, autostart, notifications, reload/edit, completions, help.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bin="$ROOT/vendor/noir/local/bin"

for s in nirupi-capture.sh nirupi-agent-selection.sh nirupi-agent-ask.sh \
         nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-agent-rewrite.sh \
         nirupi-emoji.sh nirupi-clip-transform.sh nirupi-audio.sh \
         nirupi-wallpaper.sh nirupi-tag-wallpaper.sh nirupi-reload.sh \
         nirupi-edit.sh nirupi-ssh.sh nirupi-autostart.sh nirupi-battery.sh \
         nirupi-notifications.sh nirupi-launch.sh nirupi-rofi-clip.sh \
         nirupi-rofi-files.sh nirupi-usb.sh nirupi-lid.sh; do
  [[ -f "$bin/$s" ]] || { echo "FAIL missing $s" >&2; exit 1; }
  bash -n "$bin/$s" || { echo "FAIL syntax $s" >&2; exit 1; }
  grep -q "$s" "$ROOT/lib/install.sh" || { echo "FAIL $s not deployed" >&2; exit 1; }
done

# Hostname must work without the `hostname` binary (not in a vanilla Arch base).
for s in dwm-status.sh nirupi-status-click.sh apply-screenlayout.sh nirupi-ssh.sh; do
  grep -q 'uname -n' "$bin/$s" || { echo "FAIL $s lacks a hostname fallback" >&2; exit 1; }
done

# dwm wiring: hooks + new bindings + schema bump.
DWM="$ROOT/vendor/suckless/dwm"
grep -q 'runwallhook' "$DWM/dwm.c" || { echo 'FAIL dwm tag hook missing' >&2; exit 1; }
grep -qE 'runwallhook\(\);' "$DWM/dwm.c" || { echo 'FAIL dwm hook not called' >&2; exit 1; }
grep -q 'nirupi-tag-wallpaper.sh' "$DWM/dwm.c" || { echo 'FAIL dwm hook command missing' >&2; exit 1; }
for cmd in capturecmd agentselectioncmd askscreencmd askcommandcmd agentrewritecmd sshcmd; do
  grep -q "$cmd\[\]" "$DWM/config.h" || { echo "FAIL $cmd missing" >&2; exit 1; }
done
grep -q 'nirupi-launch.sh' "$DWM/config.h" || { echo 'FAIL launcher binding missing' >&2; exit 1; }
grep -q 'nirupi-agent-rewrite.sh' "$DWM/config.h" || { echo 'FAIL rewrite binding missing' >&2; exit 1; }
grep -q 'NIRUPI_CONFIG_VERSION 7' "$DWM/config.h" || { echo 'FAIL schema not bumped' >&2; exit 1; }
grep -q 'XK_Left' "$DWM/config.h" || { echo 'FAIL arrow-key bindings missing' >&2; exit 1; }
grep -q 'nirupi-rofi-files.sh' "$bin/nirupi-launch.sh" || { echo 'FAIL launcher lacks file search' >&2; exit 1; }

# Control center + keybinding palette entries.
for e in 'Wallpapers per workspace: toggle' 'Audio output' 'USB: mount/unmount…' 'Lid close…' 'SSH / host…' 'Reload desktop…' 'Edit config…' 'Ask agent about screen…' 'AI command…' 'Notifications: history…'; do
  grep -qF "$e" "$bin/nirupi-menu.sh" || { echo "FAIL menu missing: $e" >&2; exit 1; }
done
for e in nirupi-emoji.sh nirupi-agent-selection.sh nirupi-capture.sh nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-ssh.sh nirupi-reload.sh nirupi-edit.sh nirupi-launch.sh nirupi-notifications.sh nirupi-usb.sh nirupi-lid.sh; do
  grep -q "$e" "$bin/nirupi-keys.sh" || { echo "FAIL palette missing: $e" >&2; exit 1; }
done

# Themed picom + maintenance timers + example configs.
grep -q 'theme_render_picom' "$ROOT/lib/theme.sh" || { echo 'FAIL picom generator missing' >&2; exit 1; }
grep -q 'fstrim.timer' "$ROOT/lib/install.sh" || { echo 'FAIL fstrim timer missing' >&2; exit 1; }
grep -q 'autostart' "$ROOT/lib/install.sh" || { echo 'FAIL autostart not deployed' >&2; exit 1; }
[[ -f "$ROOT/runtime/autostart.example" ]] || { echo 'FAIL autostart example missing' >&2; exit 1; }
grep -q 'BATTERY_WARN' "$ROOT/runtime/session.conf.example" || { echo 'FAIL battery config missing' >&2; exit 1; }
grep -q 'LOCK_CLEAR_CLIPBOARD' "$ROOT/runtime/session.conf.example" || { echo 'FAIL lock clipboard config missing' >&2; exit 1; }

# Completions, man page, wallpaper example.
[[ -f "$ROOT/vendor/noir/config/fish/completions/nirupi.fish" ]] || { echo 'FAIL fish completion' >&2; exit 1; }
[[ -f "$ROOT/vendor/noir/local/share/bash-completion/completions/nirupi" ]] || { echo 'FAIL bash completion' >&2; exit 1; }
[[ -f "$ROOT/runtime/nirupi.1" ]] || { echo 'FAIL man page' >&2; exit 1; }
[[ -f "$ROOT/runtime/wallpapers.conf.example" ]] || { echo 'FAIL wallpaper example' >&2; exit 1; }

# nirupi help + subtools.
out="$(bash "$ROOT/runtime/nirupi" help 2>/dev/null)"
for t in ssh edit reload launch autostart notifications usb lid; do
  grep -q "nirupi $t" <<< "$out" || { echo "FAIL help $t" >&2; exit 1; }
done
bash "$bin/nirupi-edit.sh" --list | grep -q '^  status ' || { echo 'FAIL edit --list' >&2; exit 1; }
[[ "$(bash "$bin/nirupi-edit.sh" --path dwm)" == */suckless/dwm/config.h ]] || { echo 'FAIL edit --path' >&2; exit 1; }
bash "$bin/nirupi-autostart.sh" list >/dev/null || { echo 'FAIL autostart list' >&2; exit 1; }

echo 'PASS: extras (capture, AI, emoji, clipboard, audio, wallpapers, ssh, launcher, autostart, notifications, battery, picom, reload/edit, help)'
