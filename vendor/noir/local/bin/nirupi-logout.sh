#!/bin/sh
# NIRU Noir logout — kept for backwards compatibility. The real power menu
# (screensaver, lock, suspend/logout/reboot/shutdown, with timers) lives in
# nirupi-power.sh, which Super+Shift+q opens.
exec "$HOME/.local/bin/nirupi-power.sh" "$@"
