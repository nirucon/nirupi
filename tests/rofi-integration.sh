#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
r=Path(sys.argv[1]); cfg=(r/'vendor/noir/config/rofi/config.rasi').read_text()
assert 'Black-Metal.rasi' in cfg
assert (r/'vendor/noir/local/share/rofi/themes/Black-Metal.rasi').is_file()
s=(r/'lib/install.sh').read_text()
assert 'local rofi_theme_dest="$HOME/.local/share/rofi/themes/Black-Metal.rasi"' in s
assert "managed_config_install 'rofi/Black-Metal.rasi'" in s
assert s.index('local rofi_theme_src=') < s.index('for app in kitty fish dunst picom rofi', s.index('install_desktop()'))
print('PASS: Rofi config, theme payload and deployment order')
PYTEST
