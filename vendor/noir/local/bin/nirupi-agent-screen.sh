#!/usr/bin/env bash
# NIRU: grab a region of the screen, OCR it and send the text to the AI agent.
# Needs maim (X11) and tesseract.
set -Eeuo pipefail

have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Agent "$1" >/dev/null 2>&1 || :; }

have maim || { note 'maim is required (X11 capture)'; exit 1; }
have tesseract || { note 'tesseract is required for OCR'; exit 1; }

tmp="$(mktemp --suffix=.png 2>/dev/null || mktemp)" || exit 1
trap 'rm -f -- "$tmp"' EXIT

maim -s -u "$tmp" 2>/dev/null || exit 0
[[ -s $tmp ]] || exit 0

txt="$(tesseract "$tmp" - 2>/dev/null || true)"
[[ -n ${txt//[[:space:]]/} ]] || { note 'No text found in that region'; exit 0; }

printf '%s' "$txt" | exec "$HOME/.local/bin/nirupi-agent-ask.sh"
