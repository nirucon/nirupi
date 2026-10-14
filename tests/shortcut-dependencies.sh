#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import re
import sys
r=Path(sys.argv[1]); pkg=(r/'lib/packages.sh').read_text(); install=(r/'install.sh').read_text(); shot=(r/'vendor/noir/local/bin/screenshot-select.sh').read_text()
def pkgs_for(tag):
    m=re.search(re.escape(tag)+r'\)\s*\n\s*PKGS=\(([^)]*)\)', pkg)
    return m.group(1) if m else ''
arch=pkgs_for('arch|cachyos'); deb=pkgs_for('debian')
for dep in ('maim','xclip','flameshot'):
    assert dep in arch, ('arch',dep)
    assert dep in deb, ('debian',dep)
for dep in ('slock','sxiv','gimp'):
 assert dep in install, dep
assert 'managed_helper_install nirupi-browser' in (r/'lib/install.sh').read_text()
assert 'nirupi-browser' in (r/'vendor/suckless/dwm/config.h').read_text()
assert "trap " in shot and "rm -f --" in shot
assert 'custom_name="$(printf' in shot
print('PASS: screenshot dependencies, optional shortcut diagnostics, safe temp cleanup')
PYTEST
