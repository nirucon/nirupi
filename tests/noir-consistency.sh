#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ST="$ROOT/vendor/suckless/st/config.h"
KITTY="$ROOT/vendor/noir/config/kitty/kitty.conf"
ALA="$ROOT/vendor/noir/config/alacritty/alacritty.toml"
DMENU="$ROOT/vendor/suckless/dmenu/config.h"
python3 - "$ST" "$KITTY" "$ALA" "$DMENU" <<'PYTEST'
import re,sys,pathlib
st,kitty,ala,dmenu=[pathlib.Path(x).read_text() for x in sys.argv[1:]]
a=st.split('static const char *colorname[] = {',1)[1].split('[255] = 0',1)[0]
sc=re.findall(r'"(#[0-9a-fA-F]{6})"',a)
assert len(sc)==16,len(sc)
for i,color in enumerate(sc):
 assert re.search(rf'(?m)^color{i}\s+{color}$',kitty),f'Kitty ANSI {i}'
 name=('black','red','green','yellow','blue','magenta','cyan','white')[i%8]
 sect='normal' if i<8 else 'bright'
 body=ala.split('[colors.'+sect+']',1)[1].split('\n[',1)[0]
 assert re.search(rf'(?m)^{name}\s*=\s*"0x{color[1:]}"',body),f'Alacritty ANSI {i}'
assert 'size = 11.0' in ala
assert 'JetBrainsMono Nerd Font:size=11' in dmenu
assert 'font_family      JetBrainsMono Nerd Font' in kitty
print('PASS: NIRU Noir typography and 16 ANSI colors match')
PYTEST
