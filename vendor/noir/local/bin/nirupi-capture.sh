#!/usr/bin/env bash
# NIRU capture: region / window / full screenshot with optional annotation
# (satty) and OCR-to-clipboard (tesseract). Saves to ~/Pictures/Screenshots.
set -Eeuo pipefail

dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
have(){ command -v "$1" >/dev/null 2>&1; }
note(){ have notify-send && notify-send -a NIRUPI Screenshot "$1" >/dev/null 2>&1 || :; }
copy_img(){ have xclip && xclip -selection clipboard -t image/png -i "$1" 2>/dev/null || true; }
copy_txt(){ if have wl-copy && [[ -n ${WAYLAND_DISPLAY:-} ]]; then wl-copy; elif have xclip; then xclip -selection clipboard -i; else cat >/dev/null; fi; }
stamp(){ date +%F_%H-%M-%S; }
tmpf(){ printf '%s/.capture-%s.png' "$dir" "$(stamp)"; }

have maim || { note 'maim is required for capture'; exit 1; }

grab_region(){ local o="$1"; maim -s -u "$o" 2>/dev/null; }
grab_window(){ local o="$1"; have xdotool || return 1; maim -i "$(xdotool getactivewindow)" -u "$o" 2>/dev/null; }
grab_full(){ local o="$1"; maim -u "$o" 2>/dev/null; }

finish(){ local f="$1"; copy_img "$f"; note "Saved & copied: $(basename "$f")"; }
annotate(){ # FILE -> annotated file (satty) or the same file
  local in="$1" out="${1%.png}.annot.png"
  if have satty; then
    satty --filename "$in" --output-filename "$out" --early-exit --copy-command 'xclip -selection clipboard -t image/png' 2>/dev/null || { printf '%s' "$in"; return; }
    have xclip && xclip -selection clipboard -t image/png -i "$out" 2>/dev/null || true
    printf '%s' "$out"
  else printf '%s' "$in"; fi
}
ocr(){ # FILE
  have tesseract || { note 'tesseract not installed (OCR unavailable)'; return 1; }
  local txt; txt="$(tesseract "$1" - 2>/dev/null)" || return 1
  printf '%s' "$txt" | copy_txt
  note "OCR copied to clipboard ($(printf '%s' "$txt" | wc -w) words)"
}

opts='Region → annotate
Region
Window
Full screen'
have satty || opts='Region
Window
Full screen'
have tesseract && opts="$opts
OCR from region → clipboard"

choice="$(printf '%s\n' "$opts" | { if have rofi; then rofi -dmenu -i -p 'Capture'; elif have dmenu; then dmenu -i -p 'Capture'; else cat; fi; } || true)"
[[ -n $choice ]] || exit 0

f="$(tmpf)"
case "$choice" in
  'Region → annotate') grab_region "$f" || exit 0; f="$(annotate "$f")"; finish "$f";;
  'Region')            grab_region "$f" || exit 0; finish "$f";;
  'Window')            grab_window "$f" || { note 'Window capture needs xdotool'; exit 1; }; finish "$f";;
  'Full screen')       grab_full "$f" || exit 0; finish "$f";;
  'OCR from region → clipboard') grab_region "$f" || exit 0; ocr "$f";;
  *) exit 0;;
esac
