#!/usr/bin/env bash
# Thin hook called by dwm on every tag (workspace) switch. dwm passes the
# visible tagset in $NIRUPI_TAGSET; nirupi-wallpaper.sh does the rest and can be
# disabled from the control center.
exec "$HOME/.local/bin/nirupi-wallpaper.sh" tag
