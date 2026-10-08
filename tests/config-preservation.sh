#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
s=(Path(sys.argv[1])/'lib/install.sh').read_text()
for key in ("dwm/config.h", "rofi/Black-Metal.rasi", "session/nirupi-session", "session/xinitrc", "dotfiles/Xresources"):
 assert "managed_config_install '"+key+"'" in s or 'managed_config_install '+key in s, key
assert 'managed_config_install "config/$app/' in s
print('PASS: DWM, Rofi, Xresources, session and app configs use managed deployment')
PYTEST
