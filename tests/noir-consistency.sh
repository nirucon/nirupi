#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ST="$ROOT/vendor/suckless/st/config.h"
KITTY="$ROOT/vendor/noir/config/kitty/kitty.conf"
ALA="$ROOT/vendor/noir/config/alacritty/alacritty.toml"
DMENU="$ROOT/vendor/suckless/dmenu/config.h"
TOKENS="$ROOT/vendor/noir/theme/tokens.env"
python3 - "$ST" "$KITTY" "$ALA" "$DMENU" "$TOKENS" <<'PYTEST'
import re, sys, pathlib
st, kitty, ala, dmenu, tokens = [pathlib.Path(x).read_text() for x in sys.argv[1:]]

tok = {}
for line in tokens.splitlines():
    line = line.split('#', 1)[0].strip()
    if not line or '=' not in line:
        continue
    k, v = line.split('=', 1)
    tok[k.strip()] = v.strip().strip('"')

ansi = [tok[f'NOIR_ANSI_{i}'] for i in range(16)]
assert len(ansi) == 16

body = st.split('static const char *colorname[] = {', 1)[1].split('[255] = 0', 1)[0]
sc = re.findall(r'"(#[0-9a-fA-F]{6})"', body)
assert len(sc) == 16, len(sc)
for i, color in enumerate(sc):
    assert color == '#' + ansi[i], f'st ANSI {i}: {color} != #{ansi[i]}'
    assert re.search(rf'(?m)^color{i}\s+{color}$', kitty), f'Kitty ANSI {i}'
    name = ('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')[i % 8]
    sect = 'normal' if i < 8 else 'bright'
    part = ala.split('[colors.' + sect + ']', 1)[1].split('\n[', 1)[0]
    assert re.search(rf'(?m)^{name}\s*=\s*"0x{color[1:]}"', part), f'Alacritty ANSI {i}'

assert tok['NOIR_BG'] == sc[0].lstrip('#')
assert tok['NOIR_FG'] == sc[7].lstrip('#')
assert f"background #{tok['NOIR_BG']}" in kitty
assert f"foreground #{tok['NOIR_FG']}" in kitty
assert 'background = "0x' + tok['NOIR_BG'] + '"' in ala
assert 'foreground = "0x' + tok['NOIR_FG'] + '"' in ala
assert 'size = 11.0' in ala
assert 'JetBrainsMono Nerd Font:size=11' in dmenu
assert 'font_family      JetBrainsMono Nerd Font' in kitty
print('PASS: NIRU Noir typography, tokens and 16 ANSI colors match')
PYTEST

# Newly themed tools exist and are wired into the deploy loop.
for f in \
  vendor/noir/config/tmux/tmux.conf \
  vendor/noir/config/lazygit/config.yml \
  vendor/noir/config/micro/settings.json \
  vendor/noir/config/aerc/aerc.conf \
  vendor/noir/config/brave-flags.conf \
  vendor/noir/theme/tokens.env; do
  [[ -f "$ROOT/$f" ]] || { echo "FAIL missing $f" >&2; exit 1; }
done
grep -q 'tmux lazygit micro aerc' "$ROOT/lib/install.sh"
grep -q 'tokens.env' "$ROOT/lib/theme.sh"
echo 'PASS: NIRU Noir tool coverage and theme wiring'
