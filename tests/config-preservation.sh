#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
r=Path(sys.argv[1]); s=(r/'lib/install.sh').read_text()
for key in ("dwm/config.h", "session/nirupi-session", "session/xinitrc", "dotfiles/Xresources"):
 assert "managed_config_install '"+key+"'" in s or 'managed_config_install '+key in s, key
assert 'managed_config_install "config/$app/' in s
# The rofi theme is generated from the active palette by the theme engine
# (managed, so user edits are preserved).
t=(r/'lib/theme.sh').read_text()
assert "managed_config_install 'rofi/Black-Metal.rasi'" in t
print('PASS: DWM, Rofi, Xresources, session and app configs use managed deployment')
PYTEST
