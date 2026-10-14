#!/usr/bin/env bash
# Generate docs/KEYBINDINGS.md from vendor/suckless/dwm/config.h.
# Usage: tools/gen-keybindings.sh [config.h]   (writes markdown to stdout)
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="${1:-$ROOT/vendor/suckless/dwm/config.h}"
python3 - "$CFG" <<'PY'
import re, sys, pathlib

cfg = pathlib.Path(sys.argv[1]).read_text()
block = cfg.split('static const Key keys[]', 1)[1].split('};', 1)[0]

MOD = {
    'MODKEY': 'Super', 'Mod4Mask': 'Super', 'ShiftMask': 'Shift',
    'ControlMask': 'Ctrl', 'Mod1Mask': 'Alt', 'Mod2Mask': 'Mod2',
    'Mod3Mask': 'Mod3', 'Mod5Mask': 'Mod5', 'LockMask': 'Lock',
    '0': '(none)',
}
MOD_ORDER = {'Super': 0, 'Ctrl': 1, 'Alt': 2, 'Shift': 3}

KEYS = {
    'XK_Return': 'Enter', 'XK_Escape': 'Esc', 'XK_space': 'Space',
    'XK_Tab': 'Tab', 'XK_grave': 'Backtick', 'XK_slash': '/', 'XK_comma': ',',
    'XK_period': '.', 'XK_Print': 'Print', 'XK_BackSpace': 'BackSpace',
    'XK_Left': 'Left', 'XK_Right': 'Right', 'XK_Up': 'Up', 'XK_Down': 'Down',
}


def name_key(k):
    k = k.strip()
    if k in KEYS:
        return KEYS[k]
    if k.startswith('XF86XK_'):
        return k[len('XF86XK_'):]
    if k.startswith('XK_'):
        s = k[3:]
        if re.fullmatch(r'F\d+', s):
            return s
        if len(s) == 1:
            return s.upper()
        return s
    return k


def name_mods(mask):
    out = []
    for part in mask.split('|'):
        part = part.strip()
        out.append(MOD.get(part, part))
    # preserve only known order, dedupe
    seen = []
    for m in sorted(set(out), key=lambda x: MOD_ORDER.get(x, 9)):
        seen.append(m)
    return '+'.join(seen)


rows = []
tagkeys = 0
for line in block.splitlines():
    m = re.search(r'TAGKEYS\(\s*(XK_[A-Za-z0-9_]+)\s*,\s*(\d+)\s*\)', line)
    if m:
        tag = int(m.group(2)) + 1
        key = name_key(m.group(1))
        rows.append((f'Super+{key}', f'View tag {tag}'))
        rows.append((f'Super+Ctrl+{key}', f'Toggle view tag {tag}'))
        rows.append((f'Super+Shift+{key}', f'Move window to tag {tag}'))
        rows.append((f'Super+Ctrl+Shift+{key}', f'Toggle window on tag {tag}'))
        continue
    m = re.match(r'\s*\{\s*([^,{}]+?)\s*,\s*((?:XK_|XF86XK_)[A-Za-z0-9_]+)\s*,\s*([A-Za-z0-9_]+)\s*,\s*(.*?)\s*\},?',
                 line)
    if not m:
        continue
    mask, key, func = m.group(1), m.group(2), m.group(3)
    arg = m.group(4)
    comment = ''
    cm = re.search(r'/\*\s*(.*?)\s*\*/', line)
    if cm:
        comment = cm.group(1)
        if '->' in comment:
            comment = comment.split('->', 1)[1].strip()
    if not comment:
        val = ''
        vm = re.search(r'=\s*([A-Za-z0-9_]+)', arg)
        if vm:
            val = vm.group(1)
        comment = func + (f' {val}' if val else '')
    combo = (name_mods(mask) + '+' + name_key(key)).lstrip('+')
    rows.append((combo, comment))

print('# Keybindings')
print()
print('<!-- Generated from vendor/suckless/dwm/config.h by tools/gen-keybindings.sh. Do not edit by hand. -->')
print()
print(f'{len(rows)} bindings. `Super` is the Mod4/Win key.')
print()
print('| Keys | Action |')
print('| --- | --- |')
for combo, desc in rows:
    print(f'| `{combo}` | {desc} |')
PY
