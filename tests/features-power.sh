#!/usr/bin/env bash
# v0.7.1: power menu, screensaver (runes/ASCII), night-light cycle, current
# weather (SMHI click), TUI apps in a terminal.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
SLOCK="$ROOT/vendor/suckless/slock"
BIN="$ROOT/vendor/noir/local/bin"
fail(){ echo "FAIL: $*" >&2; exit 1; }

# Screensaver binding + power menu
grep -q 'screensavercmd' "$CFG" || fail 'screensaver command missing'
grep -q 'XK_x,.*screensavercmd' "$CFG" || fail 'Super+x screensaver binding missing'
grep -q 'nirupi-power.sh' "$CFG" || fail 'power menu not bound to Super+Shift+q'
grep -q 'nirupi-power.sh' "$ROOT/lib/install.sh" || fail 'power script not deployed'

# Power menu features + distro portability
P="$BIN/nirupi-power.sh"
[[ -x $P ]] || fail 'nirupi-power.sh missing'
for s in 'Suspend in 15' 'Suspend in …' 'Reboot in 60' 'Shut down' 'Cancel scheduled' 'loginctl' 'systemctl' 'cancel_timer'; do
  grep -qF "$s" "$P" || fail "power menu missing: $s"
done

# Night-light cycle 4500/3500/2500 + off + gamma reset
N="$BIN/nirupi-nightlight.sh"
for s in 4500 3500 2500 'reset_gamma' 'off|reset'; do grep -qF "$s" "$N" || fail "night light missing: $s"; done

# Weather: current conditions + SMHI click
grep -q 'current=temperature_2m' "$BIN/dwm-status.sh" || fail 'weather is not current'
grep -q 'smhi.se' "$BIN/nirupi-menu.sh" || fail 'weather click is not SMHI'

# TUI apps open in a terminal
grep -q 'nirupresence' "$BIN/nirupi-app.sh" || fail 'app TUI list missing'
grep -qF -- '-e "$app"' "$BIN/nirupi-app.sh" || fail 'TUI apps are not opened in a terminal'

# slock screensaver mode + runic font
grep -q 'screensaver = 1' "$SLOCK/slock.c" || fail 'slock -s flag missing'
grep -q 'drawscreensaver' "$SLOCK/slock.c" || fail 'slock screensaver face missing'
grep -q 'runify' "$SLOCK/slock.c" || fail 'slock runic transliteration missing'
grep -q 'afk ' "$SLOCK/slock.c" || fail 'slock AFK timer missing'
grep -q 'runefont' "$SLOCK/config.h" || fail 'slock runic font config missing'
[[ -f "$ROOT/vendor/noir/fonts/NotoSansRunic-Regular.ttf" ]] || fail 'runic font not bundled'
grep -q 'theme_install_fonts' "$ROOT/lib/theme.sh" || fail 'fonts not installed by the theme engine'

# Screensaver: clock is never runes; the wake switches to the blurred lock.
grep -q 'applyblur' "$SLOCK/slock.c" || fail 'screensaver wake does not restore the blur'
awk '/^drawscreensaver/,/^}/' "$SLOCK/slock.c" | grep -q 'centerline(dpy, lock, clkfont' || fail 'screensaver clock is not normal digits'
awk '/^drawscreensaver/,/^}/' "$SLOCK/slock.c" | grep -q 'runicfontsmall' || fail 'screensaver hostname runes missing'

# Agent bar icon matches the AI workspace tag glyph.
LC_ALL=C grep -A1 'icon_agent()' "$BIN/dwm-status.sh" | LC_ALL=C grep -qP '\xf3\xb0\x9a\xa9' || fail 'agent icon is not the AI robot glyph'

# Calendar popup (centred) + system updater.
[[ -f "$BIN/nirupi-calendar.py" && -x "$BIN/nirupi-calendar.sh" ]] || fail 'calendar helper missing'
grep -q 'nirupi-calendar' "$ROOT/vendor/suckless/dwm/dwm.c" || fail 'calendar window not centred in dwm'
grep -q 'nirupi-calendar.sh' "$BIN/nirupi-status-click.sh" || fail 'date click does not open the calendar'
[[ -x "$BIN/nirupi-sysupdate.sh" ]] || fail 'system update helper missing'
for d in 'apt-get' 'xbps-install' 'pacman'; do grep -q "$d" "$BIN/nirupi-sysupdate.sh" || fail "sysupdate missing $d"; done
grep -q 'nirupi-updates-popup.sh' "$BIN/nirupi-status-click.sh" || fail 'updates click does not open the updates popup'
grep -q 'nirupi-sysupdate.sh' "$BIN/nirupi-updates-popup.sh" || fail 'updates popup cannot run the updater'
grep -q 'nirupi-calendar.sh' "$ROOT/lib/install.sh" || fail 'calendar not deployed'
grep -q 'nirupi-sysupdate.sh' "$ROOT/lib/install.sh" || fail 'sysupdate not deployed'

echo 'PASS: v0.7.2 (power menu, screensaver runes/ASCII + blur lock, night-light cycle, current weather/SMHI, TUI apps, calendar, system updater)'
