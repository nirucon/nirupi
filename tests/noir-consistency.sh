#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
import pathlib,re,sys
root=pathlib.Path(sys.argv[1])
st=(root/'vendor/suckless/st/config.h').read_text()
kitty=(root/'vendor/noir/config/kitty/kitty.conf').read_text()
ala=(root/'vendor/noir/config/alacritty/alacritty.toml').read_text()
dmenu=(root/'vendor/suckless/dmenu/config.h').read_text()
a=st.split('static const char *colorname[] = {',1)[1].split('[255] = 0',1)[0]
colors=re.findall(r'"(#[0-9a-fA-F]{6})"',a)
assert len(colors)==16
for i,color in enumerate(colors):
 assert re.search(rf'(?m)^color{i}\s+{color}$',kitty)
 name=('black','red','green','yellow','blue','magenta','cyan','white')[i%8]
 sect='normal' if i<8 else 'bright'
 body=ala.split('[colors.'+sect+']',1)[1].split('\n[',1)[0]
 assert re.search(rf'(?m)^{name}\s*=\s*"0x{color[1:]}"',body)
assert 'size = 11.0' in ala
assert 'JetBrainsMono Nerd Font:size=11' in dmenu
print('PASS: NIRU Noir typography and 16 ANSI colors match')
PYTEST
