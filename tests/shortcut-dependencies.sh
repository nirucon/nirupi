#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
r=Path(sys.argv[1]); pkg=(r/'lib/packages.sh').read_text(); install=(r/'install.sh').read_text(); shot=(r/'vendor/noir/local/bin/screenshot-select.sh').read_text()
for dep in ('maim','xclip','flameshot'):
 for distro in ('arch|cachyos)', 'debian)'):
  line=next(x for x in pkg.splitlines() if x.strip().startswith(distro+' PKGS='))
  assert dep in line, (distro,dep)
for dep in ('helium-browser','brave','slock','sxiv','gimp'):
 assert dep in install, dep
assert "trap " in shot and "rm -f --" in shot
assert 'custom_name="$(printf' in shot
print('PASS: screenshot dependencies, optional shortcut diagnostics, safe temp cleanup')
PYTEST
