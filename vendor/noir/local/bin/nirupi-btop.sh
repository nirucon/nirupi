#!/usr/bin/env bash
# Status-bar pop-up: btop in a floating terminal (temperature/CPU click).
set -Eeuo pipefail
term="$(command -v kitty || command -v alacritty || command -v st || true)"
[[ -n $term ]] || exit 1
case "$(basename "$term")" in
  kitty) exec kitty --class nirupi-btop --title btop -e btop;;
  *)     exec "$term" --title btop -e btop;;
esac
