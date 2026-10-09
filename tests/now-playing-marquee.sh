#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS="$ROOT/vendor/noir/local/bin/dwm-status.sh"
bash -n "$STATUS"
# Extract only the rendering function; do not launch the status bar or X11.
fn="$(sed -n '/^render_now_playing_text() {/,/^get_kernel() {/p' "$STATUS" | sed '$d')"
[[ "$fn" == *'render_now_playing_text()'* ]] || { echo "render function missing" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
export NP_TEXT_FILE="$tmp/text" NP_SEEN_FILE="$tmp/seen" NP_OFFSET_FILE="$tmp/offset" NP_STATE_FILE="$tmp/state" NP_PASSES_FILE="$tmp/passes"
export NOW_PLAYING_MAXLEN=12 NOW_PLAYING_SCROLL=1 NOW_PLAYING_SCROLL_DELAY=0 NOW_PLAYING_SCROLL_STEP=1 NOW_PLAYING_SCROLL_PASSES=0
export DATEBIN=date
eval "$fn"
full="Runemagick - A Very Long Track Title"
first="$(render_now_playing_text "$full")"
[[ "$first" == "Runemagick -" ]] || { echo "wrong first frame: $first" >&2; exit 1; }
saw_end=0
saw_wrap=0
for ((i=0;i<150;i++)); do
  frame="$(render_now_playing_text "$full")"
  [[ ${#frame} -le 12 ]] || { echo "frame too long" >&2; exit 1; }
  [[ "$frame" == *"Title"* ]] && saw_end=1
  [[ "$frame" == *"  Runemagick"* ]] && saw_wrap=1
done
(( saw_end && saw_wrap )) || { echo "marquee did not scroll and wrap" >&2; exit 1; }
[[ "$(cat "$NP_STATE_FILE")" != done ]] || { echo "unlimited scrolling stopped" >&2; exit 1; }
[[ "$(render_now_playing_text "Short")" == "Short" ]] || { echo "short text changed" >&2; exit 1; }
[[ "$(render_now_playing_text "Different artist - Different long track")" == "Different ar" ]] || { echo "track change did not reset" >&2; exit 1; }
echo "OK: now-playing marquee"
