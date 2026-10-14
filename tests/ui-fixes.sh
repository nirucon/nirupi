#!/usr/bin/env bash
# UI fixes: dmenu opens just below the bar; workspace tag icons.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/vendor/suckless/dwm/config.h"
DWM="$ROOT/vendor/suckless/dwm/dwm.c"
DMENU="$ROOT/vendor/suckless/dmenu/dmenu.c"
DMENU_CFG="$ROOT/vendor/suckless/dmenu/config.h"
fail(){ echo "FAIL: $*" >&2; exit 1; }

# dmenu clears the top bar: dwm exports the offset, dmenu reads it and honours -y.
grep -q 'NIRUPI_DMENU_Y' "$DWM" || fail 'dwm does not export NIRUPI_DMENU_Y'
grep -q 'NIRUPI_DMENU_Y' "$DMENU" || fail 'dmenu does not read NIRUPI_DMENU_Y'
grep -q -- '"-y"' "$DMENU" || fail 'dmenu lacks the -y option'
grep -q 'y += yoffset' "$DMENU" || fail 'dmenu does not apply yoffset'
grep -q 'dmenu.yoffset' "$DMENU_CFG" || fail 'dmenu.yoffset Xresource missing'

# Workspace icons: globe / 3x AI robot / folder / 3x terminal / chat.
grep -q '"\\uf0ac"' "$CFG" || fail 'tag1 (browser/globe) missing'
[[ $(grep -c '"\\U000f06a9"' "$CFG") == 3 ]] || fail 'expected 3 AI-robot tag icons'
grep -q '"\\uf07b"' "$CFG" || fail 'folder tag icon missing'
[[ $(grep -c '"\\uf120"' "$CFG") == 3 ]] || fail 'expected 3 terminal tag icons'
grep -q '"\\uf075"' "$CFG" || fail 'chat tag icon missing'

# The bar must be drawn on every monitor for the icon set to be consistent.
grep -q 'm->statusw = m->ww - drawstatusbar' "$DWM" || fail 'statusallmons missing'

echo 'PASS: UI fixes (dmenu offset under bar, workspace tag icons)'
