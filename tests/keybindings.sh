#!/usr/bin/env bash
# Verify there are no duplicate modifier+key bindings in dwm config.h and that
# the essential media/brightness keys are present.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
python3 - "$CFG" <<'PYTEST'
import re, sys, pathlib
cfg = pathlib.Path(sys.argv[1]).read_text()
block = cfg.split('static const Key keys[]', 1)[1].split('};', 1)[0]
# Explicit entries: { MASK, KEYSYM, func, ... }
entries = re.findall(r'\{\s*([^,{}]+?)\s*,\s*((?:XK_|XF86XK_)[A-Za-z0-9_]+)\s*,', block)
def norm(mask):
    return '|'.join(sorted(t.strip() for t in mask.split('|')))
seen = {}
dups = []
for mask, key in entries:
    sig = (norm(mask), key)
    if sig in seen:
        dups.append(f'{sig[0]} {sig[1]}')
    seen[sig] = True
assert not dups, 'duplicate keybindings: ' + ', '.join(dups)
required = [
    'XF86XK_AudioPlay', 'XF86XK_AudioPause', 'XF86XK_AudioNext', 'XF86XK_AudioPrev',
    'XF86XK_AudioRaiseVolume', 'XF86XK_AudioLowerVolume', 'XF86XK_AudioMute',
    'XF86XK_AudioMicMute', 'XF86XK_MonBrightnessUp', 'XF86XK_MonBrightnessDown',
]
for k in required:
    assert k in block, f'missing media key: {k}'
print(f'PASS: {len(entries)} keybindings, no collisions, media keys present')
PYTEST
# The cheat-sheet / palette must be wired and collision-safe.
for f in vendor/noir/local/bin/nirupi-keys.sh vendor/noir/local/bin/nirupi-menu.sh; do
  [[ -f "$ROOT/$f" ]] || { echo "FAIL missing $f" >&2; exit 1; }
done
# docs/KEYBINDINGS.md must not drift from config.h.
tmp="$(mktemp)"
if ! bash "$ROOT/tools/gen-keybindings.sh" > "$tmp" || ! diff -u "$ROOT/docs/KEYBINDINGS.md" "$tmp" >/dev/null; then
  echo 'FAIL: docs/KEYBINDINGS.md is out of date; run tools/gen-keybindings.sh' >&2
  rm -f "$tmp"; exit 1
fi
rm -f "$tmp"
echo 'PASS: docs/KEYBINDINGS.md matches config.h'

# The Super+Alt+k viewer (dwm-keybindings.sh) must describe launchers from the
# config comments instead of leaking raw C variable names.
viewer_out="$(bash "$ROOT/vendor/noir/local/bin/dwm-keybindings.sh" "$CFG" 2>/dev/null)"
grep -q 'theme picker' <<< "$viewer_out" || { echo 'FAIL: viewer lacks the theme picker description' >&2; exit 1; }
if grep -qE '\| (thememenu|agentcmd|menucmd|keyscmd|nightlightcmd|media_play) ' <<< "$viewer_out"; then
  echo 'FAIL: viewer leaks raw config variable names' >&2; exit 1
fi
echo 'PASS: keybinding viewer (Super+Alt+k) describes launchers'
