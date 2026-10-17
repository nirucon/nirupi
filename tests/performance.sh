#!/usr/bin/env bash
# Performance regressions: the bar must not wake at music-frame rate when idle,
# must only animate while a player is active, and must not fork a pipeline just
# to join segments.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BAR="$ROOT/vendor/noir/local/bin/dwm-status.sh"
fail(){ echo "FAIL: $*" >&2; exit 1; }

grep -q 'last_line' "$BAR" || fail 'status bar has no last_line change detection'
grep -q 'sleep "$INTERVAL"' "$BAR" || fail 'status bar does not sleep at INTERVAL when idle'
grep -q 'playerctl -l' "$BAR" || fail 'now-playing does not enumerate players once'
grep -q 'paste -sd' "$BAR" && fail 'status bar still uses paste for joining'
grep -q "printf '\[ %s \]' \"\$out\"" "$BAR" || fail 'pure-bash status join missing'
! grep -q 'for player_name in \$NOW_PLAYING_PREFERRED_PLAYERS; do[[:space:]]*$' "$BAR" || fail 'old player probe loop still present'
echo 'PASS: status bar is idle-friendly, player-aware and fork-light'
