#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
r=Path(sys.argv[1]); cfg=(r/'vendor/noir/config/rofi/config.rasi').read_text()
assert 'Black-Metal.rasi' in cfg
assert (r/'vendor/noir/local/share/rofi/themes/Black-Metal.rasi').is_file()
# The live rofi theme is generated from the active palette by the theme engine;
# the static payload above is only the name the rofi config points at.
t=(r/'lib/theme.sh').read_text()
assert 'theme_render_rofi' in t
assert "managed_config_install 'rofi/Black-Metal.rasi'" in t
s=(r/'lib/install.sh').read_text()
assert 'theme_render_rofi' in s
assert 'local rofi_theme_src=' not in s
print('PASS: Rofi config and generated theme wiring')
PYTEST
