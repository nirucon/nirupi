#!/usr/bin/env bash
# v0.7 features: lock clock, window switcher, caffeine, focus, recording, OSD,
# clipboard history, gaps, keyboard/touchpad, day/night, quick launch.
# Also enforces "no function keys" and that the viewers list every binding.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
SLOCK="$ROOT/vendor/suckless/slock"
fail(){ echo "FAIL: $*" >&2; exit 1; }

# ── No function keys anywhere in the key map ─────────────────────────────────
if grep -qE 'XK_F[0-9]+' "$CFG"; then fail 'a function key is bound (not allowed)'; fi

# ── New bindings exist ───────────────────────────────────────────────────────
grep -q 'windowsmenu' "$CFG"   || fail 'window switcher binding missing'
grep -q 'recordcmd' "$CFG"     || fail 'recording binding missing'
grep -q 'togglegaps' "$CFG"    || fail 'gaps toggle missing'
grep -q 'caffeinecmd' "$CFG"   || fail 'caffeine binding missing'
grep -q 'focuscmd' "$CFG"      || fail 'focus binding missing'
grep -q 'kblayoutcmd' "$CFG"   || fail 'keyboard layout binding missing'
grep -q 'touchpadcmd' "$CFG"   || fail 'touchpad binding missing'
grep -q 'nirunotecmd' "$CFG"   || fail 'nirunote launch binding missing'
grep -q 'nplaycmd' "$CFG"      || fail 'nplay launch binding missing'

# Bindings we explicitly moved off function keys.
grep -q 'XK_e,.*togglefullscr' "$CFG" || fail 'fullscreen not on Super+Shift+e'
grep -q 'XK_r,.*xresreload' "$CFG"    || fail 'xresreload not on Super+Shift+r'
if grep -q 'XK_F11' "$CFG"; then fail 'F11 still bound'; fi
if grep -q 'XK_F5' "$CFG"; then fail 'F5 still bound'; fi

# ── Super+Alt+k viewer is wired ──────────────────────────────────────────────
grep -q 'MODKEY|Mod1Mask, *XK_k,.*keybindingscmd' "$CFG" || fail 'Super+Alt+k viewer missing'
grep -q 'dwm-keybindings.sh' "$CFG" || fail 'viewer does not call dwm-keybindings.sh'

# ── Lock-screen clock (Xft) ──────────────────────────────────────────────────
grep -q 'XftDrawStringUtf8' "$SLOCK/slock.c" || fail 'slock clock drawing missing'
grep -q 'gethostname' "$SLOCK/slock.c" || fail 'slock hostname missing'
grep -q 'lXft' "$SLOCK/config.mk" || fail 'slock does not link Xft'
grep -q 'clockfont' "$SLOCK/config.h" || fail 'slock clock fonts missing'

# ── New helpers exist, are executable and syntactically valid ───────────────
helpers=(nirupi-osd.sh nirupi-caffeine.sh nirupi-focus.sh nirupi-record.sh
         nirupi-window.sh nirupi-keyboard.sh nirupi-touchpad.sh nirupi-app.sh
         nirupi-clipd.sh nirupi-theme-auto.sh)
for h in "${helpers[@]}"; do
  f="$ROOT/vendor/noir/local/bin/$h"
  [[ -x "$f" ]] || fail "helper missing/not executable: $h"
  bash -n "$f" || fail "helper syntax error: $h"
  grep -q "$h" "$ROOT/lib/install.sh" || fail "helper not deployed: $h"
done

# ── Wiring ───────────────────────────────────────────────────────────────────
grep -q 'nirupi-clipd.sh' "$ROOT/runtime-session.sh" || fail 'session does not start the clipboard watcher'
grep -q 'super+shift+r' "$ROOT/lib/theme.sh" || fail 'theme engine does not use the new reload key'
grep -q 'nirupi-status-click.sh caffeine", *31' "$CFG" || fail 'caffeine status id missing'
grep -q 'get_caffeine' "$ROOT/vendor/noir/local/bin/dwm-status.sh" || fail 'caffeine status segment missing'
grep -q 'caffeine' "$ROOT/vendor/noir/local/bin/nirupi-menu.sh" || fail 'caffeine missing from control center'
grep -q 'Tailscale: toggle' "$ROOT/vendor/noir/local/bin/nirupi-menu.sh" || fail 'tailscale entry missing'
grep -q 'nirupi-theme-auto.sh' "$ROOT/lib/install.sh" || fail 'theme-auto not deployed'

# ── Both viewers list every tag binding ──────────────────────────────────────
keys_out="$(NIRUPI_DWM_CONFIG="$CFG" bash "$ROOT/vendor/noir/local/bin/nirupi-keys.sh" --list)"
grep -q 'View tag' <<< "$keys_out" || fail 'nirupi-keys.sh does not list tag bindings'
dwm_keys_out="$(bash "$ROOT/vendor/noir/local/bin/dwm-keybindings.sh" "$CFG" 2>/dev/null)"
grep -q 'Tags' <<< "$dwm_keys_out" || fail 'dwm-keybindings.sh has no Tags section'
grep -q 'toggletag' <<< "$dwm_keys_out" || fail 'dwm-keybindings.sh does not list tag bindings'

# ── KEYBINDINGS.md in sync ───────────────────────────────────────────────────
tmp="$(mktemp)"
bash "$ROOT/tools/gen-keybindings.sh" > "$tmp" || fail 'keybindings generator failed'
diff -q "$ROOT/docs/KEYBINDINGS.md" "$tmp" >/dev/null || fail 'KEYBINDINGS.md out of date'
rm -f "$tmp"

echo 'PASS: v0.7 features (lock clock, switcher, caffeine, focus, recording, OSD, clipboard, gaps, input, theme, apps)'
