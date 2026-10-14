#!/usr/bin/env bash
# Toggle a screen recording into ~/Videos/Recordings. X11 uses ffmpeg x11grab
# (detected by the status-bar "recording" segment); Wayland uses wf-recorder.
set -Eeuo pipefail

dir="$HOME/Videos/Recordings"
flag="${XDG_CACHE_HOME:-$HOME/.cache}/nirupi/recording.pid"
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "$@" || :; }

if [[ -f $flag ]] && kill -0 "$(cat "$flag")" 2>/dev/null; then
  kill -INT "$(cat "$flag")" 2>/dev/null || :
  rm -f -- "$flag"
  notify -u normal "Recording stopped" "$dir"
  exit 0
fi

mkdir -p "$dir"
out="$dir/$(date +%F_%H-%M-%S).mp4"
if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wf-recorder >/dev/null 2>&1; then
  setsid wf-recorder -f "$out" >/dev/null 2>&1 &
elif [[ -n ${DISPLAY:-} ]] && command -v ffmpeg >/dev/null 2>&1; then
  setsid ffmpeg -hide_banner -loglevel error -f x11grab -framerate 30 \
    -i "$DISPLAY" -c:v libx264 -preset ultrafast -pix_fmt yuv420p "$out" >/dev/null 2>&1 &
else
  notify -u critical "Recording" "Need ffmpeg (X11) or wf-recorder (Wayland)"
  exit 1
fi
pid=$!
sleep 0.7
if kill -0 "$pid" 2>/dev/null; then
  echo "$pid" > "$flag"
  notify -u normal "Recording started" "Super+r to stop · $dir"
else
  notify -u critical "Recording" "Failed to start"
fi
