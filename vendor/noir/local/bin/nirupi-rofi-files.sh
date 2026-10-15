#!/usr/bin/env bash
# rofi "script mode" for the NIRU launcher: file search.
# Called with no args -> print matching files. Called with a path -> open it.
# Uses fd/fdfind when present (already installed with NIRUPI), else find.
set -Eeuo pipefail
root="${NIRUPI_SEARCH_DIR:-$HOME}"

open_it(){
  local f="$1"
  [[ -e $f ]] || exit 0
  if command -v xdg-open >/dev/null 2>&1; then
    setsid xdg-open "$f" >/dev/null 2>&1 &
  elif [[ -n ${EDITOR:-} ]] && command -v "${EDITOR%% *}" >/dev/null 2>&1; then
    setsid ${EDITOR} "$f" >/dev/null 2>&1 &
  fi
}

if [[ $# -ge 1 ]]; then
  open_it "$1"
  exit 0
fi

if command -v fd >/dev/null 2>&1; then
  fd --type f --hidden --follow \
    --exclude .git --exclude node_modules --exclude .cache \
    --exclude .local/share/Trash --exclude .mozilla \
    . "$root" 2>/dev/null | head -n 3000 || true
elif command -v fdfind >/dev/null 2>&1; then
  fdfind --type f --hidden --follow \
    --exclude .git --exclude node_modules --exclude .cache \
    . "$root" 2>/dev/null | head -n 3000 || true
else
  find "$root" -type f \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.cache/*' \
    2>/dev/null | head -n 3000 || true
fi
