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
         nirupi-rofi-files.sh nirupi-usb.sh nirupi-lid.sh nirupi-barmode.sh \
         nirupi-updatecheck.sh nirupi-popup.sh nirupi-updates-popup.sh \
         nirupi-battery-popup.sh nirupi-disk-popup.sh nirupi-weather-popup.sh \
         nirupi-btop.sh nirupi-changes.sh nirupi-fleet.sh nirupi-panel.py; do
  [[ -f "$bin/$s" ]] || { echo "FAIL missing $s" >&2; exit 1; }
  case "$s" in *.py) python3 -m py_compile "$bin/$s";; *) bash -n "$bin/$s";; esac || { echo "FAIL syntax $s" >&2; exit 1; }
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
grep -q 'NIRUPI_CONFIG_VERSION 15' "$DWM/config.h" || { echo 'FAIL schema not bumped' >&2; exit 1; }
grep -q 'barmode,' "$DWM/config.h" && grep -q '^barmode(const Arg' "$DWM/dwm.c" \
  || { echo 'FAIL barmode missing' >&2; exit 1; }
for fn in togglesticky movefloat resizefloat; do
  grep -q "$fn," "$DWM/config.h" && grep -q "^$fn(const Arg" "$DWM/dwm.c" \
    || { echo "FAIL $fn missing" >&2; exit 1; }
done
grep -q 'dwindle }' "$DWM/config.h" && grep -q '^dwindle(Monitor' "$DWM/dwm.c" \
  || { echo 'FAIL fibonacci/dwindle layout missing' >&2; exit 1; }
grep -q 'nirupi-status-click.sh photos' "$DWM/config.h" \
  && grep -q 'nirupi-status-click.sh videos' "$DWM/config.h" \
  || { echo 'FAIL media click ids missing' >&2; exit 1; }
grep -q 'sect 22 ' "$bin/dwm-status.sh" && grep -q 'sect 30 ' "$bin/dwm-status.sh" \
  || { echo 'FAIL media sections not split' >&2; exit 1; }
grep -q 'XK_Left' "$DWM/config.h" || { echo 'FAIL arrow-key bindings missing' >&2; exit 1; }
grep -q 'nirupi-rofi-files.sh' "$bin/nirupi-launch.sh" || { echo 'FAIL launcher lacks file search' >&2; exit 1; }
grep -q 'migrate_binaries_rebuild' "$ROOT/lib/install.sh" || { echo 'FAIL binaries rebuild missing' >&2; exit 1; }
grep -q 'binaries' "$ROOT/lib/migrate.sh" || { echo 'FAIL binaries subcommand missing' >&2; exit 1; }
# Icons must be real UTF-8, never \u/\U printf escapes (bash only expands those
# in a UTF-8 locale, so they render as literal text on bare installs).
if grep -rnE '\\u[0-9A-Fa-f]{4}|\\U[0-9A-Fa-f]{8}' "$bin" --include='*.sh'; then
  echo 'FAIL locale-dependent \u escapes in helper scripts' >&2; exit 1
fi

# Control center + keybinding palette entries.
for e in 'Wallpapers per workspace: toggle' 'Audio output' 'USB: mount/unmount…' 'Lid close…' 'Bar mode (padded/full/none)' 'SSH / host…' 'Reload desktop…' 'Edit config…' 'Ask agent about screen…' 'AI command…' 'Notifications: history…'; do
  grep -qF "$e" "$bin/nirupi-menu.sh" || { echo "FAIL menu missing: $e" >&2; exit 1; }
done
for e in nirupi-emoji.sh nirupi-agent-selection.sh nirupi-capture.sh nirupi-agent-screen.sh nirupi-ask-command.sh nirupi-ssh.sh nirupi-reload.sh nirupi-edit.sh nirupi-launch.sh nirupi-notifications.sh nirupi-usb.sh nirupi-lid.sh nirupi-barmode.sh nirupi-calendar.sh; do
  grep -q "$e" "$bin/nirupi-keys.sh" || { echo "FAIL palette missing: $e" >&2; exit 1; }
done

# Themed picom + maintenance timers + example configs.
grep -q 'theme_render_picom' "$ROOT/lib/theme.sh" || { echo 'FAIL picom generator missing' >&2; exit 1; }
grep -q 'fstrim.timer' "$ROOT/lib/install.sh" || { echo 'FAIL fstrim timer missing' >&2; exit 1; }
grep -q 'autostart' "$ROOT/lib/install.sh" || { echo 'FAIL autostart not deployed' >&2; exit 1; }
[[ -f "$ROOT/runtime/autostart.example" ]] || { echo 'FAIL autostart example missing' >&2; exit 1; }
grep -q 'BATTERY_WARN' "$ROOT/runtime/session.conf.example" || { echo 'FAIL battery config missing' >&2; exit 1; }
grep -q 'LOCK_CLEAR_CLIPBOARD' "$ROOT/runtime/session.conf.example" || { echo 'FAIL lock clipboard config missing' >&2; exit 1; }
[[ -f "$ROOT/runtime/calendar.conf.example" ]] || { echo 'FAIL calendar example missing' >&2; exit 1; }
grep -q 'nirupi-updatecheck.sh' "$ROOT/runtime-session.sh" || { echo 'FAIL daily update check not wired' >&2; exit 1; }
grep -q 'calendar.conf' "$ROOT/lib/install.sh" || { echo 'FAIL calendar.conf not deployed' >&2; exit 1; }
grep -q 'nirupi-info' "$DWM/config.h" || { echo 'FAIL info popup float rule missing' >&2; exit 1; }
grep -q 'saved = 15' "$DWM/dwm.c" || { echo 'FAIL gaps reset fix missing' >&2; exit 1; }
grep -q 'issticky' "$DWM/dwm.c" || { echo 'FAIL sticky marker missing' >&2; exit 1; }
grep -q 'no clipboard tool' "$DWM/config.h" || { echo 'FAIL screenshot clipboard fallback missing' >&2; exit 1; }
grep -q 'tool-$_t' "$ROOT/runtime/nirupi" || { echo 'FAIL doctor tool checks missing' >&2; exit 1; }
grep -q 'caffeine' "$ROOT/runtime-session.sh" || { echo 'FAIL caffeine recovery missing' >&2; exit 1; }
grep -q 'nirupi-updates-popup.sh' "$bin/nirupi-status-click.sh" || { echo 'FAIL updates popup not wired' >&2; exit 1; }
grep -q 'nirupi-btop.sh' "$bin/nirupi-status-click.sh" || { echo 'FAIL btop on temp not wired' >&2; exit 1; }
grep -q 'drow OK session' "$ROOT/runtime/nirupi" && grep -q 'drow HINT locale' "$ROOT/runtime/nirupi" \
  || { echo 'FAIL doctor session/locale checks missing' >&2; exit 1; }
[[ -f "$ROOT/runtime/fleet.conf.example" ]] || { echo 'FAIL fleet example missing' >&2; exit 1; }
grep -q 'DisplayPort-5' "$bin/apply-screenlayout.sh" && grep -q 'rotate inverted' "$bin/apply-screenlayout.sh" \
  || { echo 'FAIL othala screen layout missing' >&2; exit 1; }
grep -q 'xrandr --auto' "$bin/apply-screenlayout.sh" || { echo 'FAIL screen layout guard missing' >&2; exit 1; }
grep -q 'apply-screenlayout.sh' "$ROOT/runtime-session.sh" || { echo 'FAIL screen layout not applied at session start' >&2; exit 1; }
grep -qF 'Apply screen layout' "$bin/nirupi-menu.sh" || { echo 'FAIL control center lacks Apply screen layout' >&2; exit 1; }

# Completions, man page, wallpaper example.
[[ -f "$ROOT/vendor/noir/config/fish/completions/nirupi.fish" ]] || { echo 'FAIL fish completion' >&2; exit 1; }
[[ -f "$ROOT/vendor/noir/local/share/bash-completion/completions/nirupi" ]] || { echo 'FAIL bash completion' >&2; exit 1; }
[[ -f "$ROOT/runtime/nirupi.1" ]] || { echo 'FAIL man page' >&2; exit 1; }
[[ -f "$ROOT/runtime/wallpapers.conf.example" ]] || { echo 'FAIL wallpaper example' >&2; exit 1; }

# nirupi help + subtools.
out="$(bash "$ROOT/runtime/nirupi" help 2>/dev/null)"
for t in ssh edit reload launch autostart notifications usb lid barmode calendar; do
  grep -q "nirupi $t" <<< "$out" || { echo "FAIL help $t" >&2; exit 1; }
done
bash "$bin/nirupi-edit.sh" --list | grep -q '^  status ' || { echo 'FAIL edit --list' >&2; exit 1; }
[[ "$(bash "$bin/nirupi-edit.sh" --path dwm)" == */suckless/dwm/config.h ]] || { echo 'FAIL edit --path' >&2; exit 1; }
bash "$bin/nirupi-autostart.sh" list >/dev/null || { echo 'FAIL autostart list' >&2; exit 1; }

echo 'PASS: extras (capture, AI, emoji, clipboard, audio, wallpapers, ssh, launcher, autostart, notifications, battery, picom, reload/edit, help)'
