#!/bin/sh
# NIRU Noir lock wrapper. Wakes the display (so the lock prompt is visible),
# then locks with slock (which blurs the current root via Imlib2).
export PATH="$HOME/.local/bin:$PATH"

command -v xset >/dev/null 2>&1 && xset dpms force on 2>/dev/null || :

# Clear the clipboard and primary selection on lock (security). Disable with
# LOCK_CLEAR_CLIPBOARD=0 in ~/.config/nirupi/session.conf.
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/session.conf"
cc="$(sed -n 's/^[[:space:]]*LOCK_CLEAR_CLIPBOARD[[:space:]]*=[[:space:]]*//p' "$conf" 2>/dev/null | tail -n1)"
if [ "${cc:-1}" = 1 ] && command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard -i </dev/null 2>/dev/null || :
  xclip -selection primary -i </dev/null 2>/dev/null || :
fi

lock="${NIRUPI_LOCK_BIN:-slock}"
if command -v "$lock" >/dev/null 2>&1; then
  exec "$lock" "$@"
fi
printf '%s\n' 'nirupi-lock: slock not found; install it or set NIRUPI_LOCK_BIN' >&2
exit 1
