#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
s=(Path(sys.argv[1])/'lib/install.sh').read_text()
assert 'Preserving existing DWM config' in s
assert 'if [[ -e $dwm_cfg || -L $dwm_cfg ]]' in s
assert 'put_file "$ROOT/vendor/suckless/dwm/config.h" "$dwm_cfg"' in s
assert 'Preserving non-directory config path' in s
assert 'Preserving existing user session launcher' in s
assert 'put_file "$ROOT/runtime-session.sh" "$user_session" 0755' in s
print('PASS: DWM config, directory collision and session launcher guards')
PYTEST
