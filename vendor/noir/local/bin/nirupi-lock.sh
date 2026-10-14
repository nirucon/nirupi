#!/bin/sh
# NIRU Noir lock wrapper. Wakes the display (so the lock prompt is visible),
# then locks with slock (which blurs the current root via Imlib2).
export PATH="$HOME/.local/bin:$PATH"

command -v xset >/dev/null 2>&1 && xset dpms force on 2>/dev/null || :

lock="${NIRUPI_LOCK_BIN:-slock}"
if command -v "$lock" >/dev/null 2>&1; then
  exec "$lock"
fi
printf '%s\n' 'nirupi-lock: slock not found; install it or set NIRUPI_LOCK_BIN' >&2
exit 1
