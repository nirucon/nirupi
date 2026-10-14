#!/usr/bin/env bash
# Palette + theme-engine consistency.
# The compiled suckless defaults (st/dmenu/slock) still carry the Noir palette;
# every app config now *includes* a generated colour fragment so switching the
# active theme restyles everything without a rebuild.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ST="$ROOT/vendor/suckless/st/config.h"
DMENU="$ROOT/vendor/suckless/dmenu/config.h"
SLOCK="$ROOT/vendor/suckless/slock/config.h"
TOKENS="$ROOT/vendor/noir/theme/tokens.env"
python3 - "$ST" "$DMENU" "$SLOCK" "$TOKENS" "$ROOT/vendor/noir/theme" <<'PYTEST'
import re, sys, pathlib

st, dmenu, slock, tokens = [pathlib.Path(x) for x in sys.argv[1:5]]
theme_dir = pathlib.Path(sys.argv[5])

def parse(path):
    tok = {}
    for line in path.read_text().splitlines():
        line = line.split('#', 1)[0].strip()
        if not line or '=' not in line:
            continue
        k, v = line.split('=', 1)
        tok[k.strip()] = v.strip().strip('"')
    return tok

tok = parse(tokens)
ansi = [tok[f'NOIR_ANSI_{i}'] for i in range(16)]
assert len(ansi) == 16

# --- compiled st defaults mirror the Noir palette -------------------------
body = st.read_text().split('static const char *colorname[] = {', 1)[1].split('[255] = 0', 1)[0]
sc = re.findall(r'"(#[0-9a-fA-F]{6})"', body)
assert len(sc) == 16, len(sc)
for i, color in enumerate(sc):
    assert color == '#' + ansi[i], f'st ANSI {i}: {color} != #{ansi[i]}'
assert tok['NOIR_BG'] == sc[0].lstrip('#')
assert tok['NOIR_FG'] == sc[7].lstrip('#')

# --- compiled dmenu defaults ---------------------------------------------
d = re.findall(r'"(#[0-9a-fA-F]{6})"', dmenu.read_text())
assert d[0] == '#' + tok['NOIR_MUTED'] and d[1] == '#' + tok['NOIR_BG'], d[:2]
assert d[2] == '#' + tok['NOIR_FG'] and d[3] == '#' + tok['NOIR_SELECTION'], d[:4]

# --- compiled slock defaults ---------------------------------------------
s = re.findall(r'"(#[0-9a-fA-F]{6})"', slock.read_text())
assert '#' + tok['NOIR_BG'] in s, 'slock init colour'
assert '#' + tok['NOIR_SELECTION'] in s, 'slock input colour'
assert '#' + tok['NOIR_ANSI_1'] in s, 'slock failed colour'

# --- every palette file carries the full schema --------------------------
required = ['NOIR_BG', 'NOIR_FG', 'NOIR_MUTED', 'NOIR_SELECTION', 'NOIR_BORDER',
            'NOIR_FOCUS', 'NOIR_FONT', 'NOIR_FONT_SIZE', 'NOIR_THEME_NAME']
for env in sorted(theme_dir.glob('*.env')):
    p = parse(env)
    for key in required:
        assert key in p and p[key] != '', f'{env.name}: missing {key}'
    for i in range(16):
        v = p.get(f'NOIR_ANSI_{i}', '')
        assert re.fullmatch(r'[0-9a-f]{6}', v), f'{env.name}: NOIR_ANSI_{i}={v!r}'
    for key in ('NOIR_BG', 'NOIR_FG', 'NOIR_MUTED', 'NOIR_SELECTION', 'NOIR_BORDER', 'NOIR_FOCUS'):
        assert re.fullmatch(r'[0-9a-f]{6}', p[key]), f'{env.name}: {key}={p[key]!r}'
print('PASS: palettes, tokens and compiled suckless defaults are consistent')
PYTEST

# --- app configs delegate their colours to the generated fragments --------
grep -q 'include ${HOME}/.config/nirupi/theme/kitty.conf' "$ROOT/vendor/noir/config/kitty/kitty.conf"
grep -q 'nirupi/theme/alacritty.toml' "$ROOT/vendor/noir/config/alacritty/alacritty.toml"
grep -q 'nirupi/theme/fish.fish' "$ROOT/vendor/noir/config/fish/config.fish"
grep -q 'nirupi/theme/tmux.conf' "$ROOT/vendor/noir/config/tmux/tmux.conf"
grep -q '"colorscheme": "nirupi"' "$ROOT/vendor/noir/config/micro/settings.json"
grep -q 'styleset-name = nirupi' "$ROOT/vendor/noir/config/aerc/aerc.conf"

# --- the engine generates every fragment ----------------------------------
for fn in theme_render_kitty theme_render_alacritty theme_render_fish \
          theme_render_tmux theme_render_lazygit theme_render_micro \
          theme_render_aerc theme_render_cmus theme_render_statusbar; do
  grep -q "$fn" "$ROOT/lib/theme.sh" || { echo "FAIL missing $fn in lib/theme.sh" >&2; exit 1; }
done
echo 'PASS: theme fragments are wired into the engine'
