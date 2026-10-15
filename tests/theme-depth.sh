#!/usr/bin/env bash
# R2 theme depth: st/dmenu Xresources, generated rofi/dunst/SDDM, palettes, lock.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }

# st + dmenu read runtime Xresources so the theme applies without a rebuild.
grep -q 'XResPref' "$ROOT/vendor/suckless/st/x.c" || fail 'st xresources code missing'
grep -q 'st.foreground' "$ROOT/vendor/suckless/st/config.h" || fail 'st resources missing'
grep -q 'xresreload' "$ROOT/vendor/suckless/st/x.c" || fail 'st xresreload missing'
grep -q 'XResPref' "$ROOT/vendor/suckless/dmenu/dmenu.c" || fail 'dmenu xresources code missing'
grep -q 'dmenu.foreground' "$ROOT/vendor/suckless/dmenu/config.h" || fail 'dmenu resources missing'
# theme engine writes st./dmenu. keys the binaries read.
grep -q 'st.color' "$ROOT/lib/theme.sh" || fail 'st.color not generated'
grep -q 'dmenu.selforeground' "$ROOT/lib/theme.sh" || fail 'dmenu sel colors not generated'
grep -q 'st.font' "$ROOT/lib/theme.sh" || fail 'st.font not generated'

# rofi/dunst/SDDM generated from tokens.
grep -q 'theme_render_rofi' "$ROOT/lib/theme.sh" || fail 'rofi generator missing'
# The generated rofi theme must set element-text explicitly (rofi otherwise
# inherits a dark default foreground and the list becomes unreadable).
grep -q 'element-text { background-color: transparent; text-color: @normal-foreground; }' "$ROOT/lib/theme.sh" \
  || fail 'rofi theme lacks explicit element-text text-color'
grep -q 'text-color:                  #%s;' "$ROOT/lib/theme.sh" || fail 'rofi theme lacks global text-color'
grep -q 'theme_render_dunst' "$ROOT/lib/theme.sh" || fail 'dunst generator missing'
grep -q 'dunstrc.d/90-nirupi.conf' "$ROOT/lib/theme.sh" || fail 'dunst drop-in path missing'
grep -q 'theme_render_sddm' "$ROOT/lib/theme.sh" || fail 'sddm generator missing'
grep -q 'BEGIN NIRU-NOIR-COLORS' "$ROOT/vendor/sddm/Main.qml" || fail 'sddm color markers missing'
grep -q 'vendor/sddm' "$ROOT/lib/install.sh" || fail 'sddm not deployed with the bundle'

# Built-in palettes + list/preview/set/menu.
for p in tokens.env Noir-warm.env Noir-cool.env Satie.env Carl-Larsson.env Hackerman.env Nord-Dark.env; do
  [[ -f "$ROOT/vendor/noir/theme/$p" ]] || fail "missing palette $p"
done
grep -q 'theme_list' "$ROOT/lib/theme.sh" || fail 'theme list missing'
grep -q 'theme_preview' "$ROOT/lib/theme.sh" || fail 'theme preview missing'
grep -q 'theme_set' "$ROOT/lib/theme.sh" || fail 'theme set missing'
grep -q 'theme_menu' "$ROOT/lib/theme.sh" || fail 'theme menu missing'

# Generated per-app colour fragments (include-driven, always rewritten).
for fn in theme_render_kitty theme_render_alacritty theme_render_fish \
          theme_render_tmux theme_render_lazygit theme_render_micro \
          theme_render_aerc theme_render_cmus theme_render_statusbar \
          theme_reload_running; do
  grep -q "$fn" "$ROOT/lib/theme.sh" || fail "missing $fn"
done
grep -q 'theme_gen_dir' "$ROOT/lib/theme.sh" || fail 'generated theme dir missing'

# Theme picker is reachable from dwm, the control center and the palette.
grep -q 'thememenu' "$ROOT/vendor/suckless/dwm/config.h" || fail 'dwm theme picker missing'
grep -q 'XK_t' "$ROOT/vendor/suckless/dwm/config.h" || fail 'theme keybinding missing'
grep -q 'Theme: choose' "$ROOT/vendor/noir/local/bin/nirupi-menu.sh" || fail 'control center theme entry missing'

# Noir lock wrapper and slock palette.
[[ -f "$ROOT/vendor/noir/local/bin/nirupi-lock.sh" ]] || fail 'lock wrapper missing'
grep -q 'nirupi-lock.sh' "$ROOT/lib/install.sh" || fail 'lock wrapper not deployed'
grep -q '#0f0f10' "$ROOT/vendor/suckless/slock/config.h" || fail 'slock not Noir colored'
grep -q 'lock)' "$ROOT/runtime/nirupi" || fail 'nirupi lock CLI missing'

echo 'PASS: theme depth (st/dmenu Xresources, generated rofi/dunst/SDDM, palettes, lock)'
