#!/bin/sh
# Shared X11 entry point for SDDM and startx.
export PATH="$HOME/.local/bin:$PATH"
# Validate the session before spawning notification, bar or wallpaper daemons.
if [ -z "${DISPLAY:-}" ]; then
  printf '%s\n' '[NIRUPI] DISPLAY is unset; launch via SDDM or startx' >&2
  exit 1
fi
if [ ! -x "$HOME/.local/bin/dwm" ]; then
  printf "%s\n" "[NIRUPI] DWM binary missing: $HOME/.local/bin/dwm" >&2
  exit 127
fi

# ── Session bus (startx may not provide one; SDDM usually does) ───────────────
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-launch >/dev/null 2>&1; then
  eval "$(dbus-launch --sh-syntax)"
fi
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment DISPLAY XAUTHORITY 2>/dev/null || :
fi

# ── User session preferences ──────────────────────────────────────────────────
SESSION_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/session.conf"
[ -r "$SESSION_CONF" ] && . "$SESSION_CONF"
IDLE_DIM_MINUTES="${IDLE_DIM_MINUTES:-5}"
IDLE_LOCK_MINUTES="${IDLE_LOCK_MINUTES:-10}"
IDLE_DPMS_MINUTES="${IDLE_DPMS_MINUTES:-0}"
IDLE_SUSPEND_MINUTES="${IDLE_SUSPEND_MINUTES:-0}"
IDLE_WARN_SECONDS="${IDLE_WARN_SECONDS:-30}"
LOCK_ON_SUSPEND="${LOCK_ON_SUSPEND:-1}"
START_DUNST="${START_DUNST:-1}"
START_PICOM="${START_PICOM:-1}"
LOCKER="$HOME/.local/bin/nirupi-lock.sh"
[ -x "$LOCKER" ] || LOCKER=slock

[ -r "$HOME/.Xresources" ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge "$HOME/.Xresources"
[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/xresources.noir" ] && command -v xrdb >/dev/null 2>&1 && xrdb -merge "${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/xresources.noir"

# NIRU Noir dark session environment (GTK, Qt, cursor, true color).
export GTK_THEME="Adwaita:dark"
[ -f "$HOME/.gtkrc-2.0" ] && export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
command -v qt5ct >/dev/null 2>&1 && export QT_QPA_PLATFORMTHEME=qt5ct
command -v qt6ct >/dev/null 2>&1 && export QT_QPA_PLATFORMTHEME=qt6ct
command -v kvantummanager >/dev/null 2>&1 && export QT_STYLE_OVERRIDE=kvantum
export XCURSOR_THEME="${XCURSOR_THEME:-Adwaita}"
export COLORTERM=truecolor
command -v setxkbmap >/dev/null 2>&1 && setxkbmap se
command -v xsetroot >/dev/null 2>&1 && xsetroot -solid '#0f0f10'

# Per-workspace wallpaper for the initial tag (no-op when disabled).
PER_TAG=0
if [ -x "$HOME/.local/bin/nirupi-wallpaper.sh" ]; then
  [ "$("$HOME/.local/bin/nirupi-wallpaper.sh" per-tag status 2>/dev/null)" = on ] && PER_TAG=1
fi
if [ "$PER_TAG" = 1 ]; then
  if [ -x "$HOME/.local/bin/nirupi-tag-wallpaper.sh" ]; then
    NIRUPI_TAGSET=1 "$HOME/.local/bin/nirupi-tag-wallpaper.sh" >/dev/null 2>&1 &
  fi
fi

STATUS_PID= WALL_PID= DUNST_PID= PICOM_PID= IDLE_PID= LOCK_PID= CLIP_PID= BAT_PID=
if [ "$START_PICOM" = 1 ] && command -v picom >/dev/null 2>&1 && ! pgrep -u "$(id -u)" -x picom >/dev/null 2>&1; then
  picom & PICOM_PID=$!
fi
if [ "$START_DUNST" = 1 ] && command -v dunst >/dev/null 2>&1 && ! pgrep -u "$(id -u)" -x dunst >/dev/null 2>&1; then
  dunst & DUNST_PID=$!
fi
if command -v dwm-status.sh >/dev/null 2>&1; then
  if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -f '[/]dwm-status.sh' >/dev/null 2>&1; then
    printf '%s\n' '[NIRUPI] Existing status process detected; skipping duplicate' >&2
  else
    dwm-status.sh & STATUS_PID=$!
  fi
fi
if [ "$PER_TAG" != 1 ] && command -v wallrotate.sh >/dev/null 2>&1; then
  if [ -d "${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}" ]; then
    wallrotate.sh & WALL_PID=$!
  fi
fi

# ── Automatic clipboard history (text) for the Super+v clipboard menu ─────────
if command -v nirupi-clipd.sh >/dev/null 2>&1; then
  if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -f '[/]nirupi-clipd.sh' >/dev/null 2>&1; then
    printf '%s\n' '[NIRUPI] Existing clipboard watcher detected; skipping duplicate' >&2
  else
    nirupi-clipd.sh & CLIP_PID=$!
  fi
fi

# ── Idle ladder: dim -> lock -> DPMS off -> suspend ───────────────────────────
# Each step is optional; deltas are computed for xidlehook (which chains timers).
idle_dim_cmd='command -v brightnessctl >/dev/null 2>&1 && brightnessctl -s set 20% || xset dpms force off'
idle_undim_cmd='command -v brightnessctl >/dev/null 2>&1 && brightnessctl -r || xset dpms force on'
idle_suspend_cmd='command -v systemctl >/dev/null 2>&1 && systemctl suspend || { command -v loginctl >/dev/null 2>&1 && loginctl suspend || { command -v zzz >/dev/null 2>&1 && zzz; }; }'

start_idle() {
  if command -v xidlehook >/dev/null 2>&1; then
    set --
    prev=0
    if [ "$IDLE_DIM_MINUTES" -gt 0 ] 2>/dev/null; then
      d=$((IDLE_DIM_MINUTES - prev)); [ "$d" -lt 1 ] && d=1
      set -- "$@" --timer "$((d * 60))" "$idle_dim_cmd" "$idle_undim_cmd"
      prev=$IDLE_DIM_MINUTES
    fi
    if [ "$IDLE_LOCK_MINUTES" -gt 0 ] 2>/dev/null; then
      d=$((IDLE_LOCK_MINUTES - prev)); [ "$d" -lt 1 ] && d=1
      set -- "$@" --timer "$((d * 60))" "$LOCKER" ""
      prev=$IDLE_LOCK_MINUTES
    fi
    if [ "$IDLE_DPMS_MINUTES" -gt 0 ] 2>/dev/null; then
      d=$((IDLE_DPMS_MINUTES - prev)); [ "$d" -lt 1 ] && d=1
      set -- "$@" --timer "$((d * 60))" 'xset dpms force off' 'xset dpms force on'
      prev=$IDLE_DPMS_MINUTES
    fi
    if [ "$IDLE_SUSPEND_MINUTES" -gt 0 ] 2>/dev/null; then
      d=$((IDLE_SUSPEND_MINUTES - prev)); [ "$d" -lt 1 ] && d=1
      set -- "$@" --timer "$((d * 60))" "$idle_suspend_cmd" ""
      prev=$IDLE_SUSPEND_MINUTES
    fi
    if [ "$prev" -gt 0 ]; then
      xidlehook --not-when-fullscreen --not-when-audio "$@" & IDLE_PID=$!
      return 0
    fi
  fi
  if [ "$IDLE_LOCK_MINUTES" -gt 0 ] 2>/dev/null && command -v xautolock >/dev/null 2>&1; then
    xautolock -time "$IDLE_LOCK_MINUTES" -locker "$LOCKER" -notify "$IDLE_WARN_SECONDS" \
      -notifier "notify-send -u normal 'NIRUPI' 'Screen locks in ${IDLE_WARN_SECONDS}s'" & IDLE_PID=$!
    return 0
  fi
  if [ "$IDLE_LOCK_MINUTES" -gt 0 ] 2>/dev/null && command -v xss-lock >/dev/null 2>&1; then
    xset s "$((IDLE_LOCK_MINUTES * 60))" "$((IDLE_LOCK_MINUTES * 60))" 2>/dev/null || :
    xss-lock -- "$LOCKER" & IDLE_PID=$!
    return 0
  fi
  printf '%s\n' '[NIRUPI] No idle tool found (xidlehook/xautolock/xss-lock)' >&2
}
start_idle

# ── Lock on suspend (logind) ──────────────────────────────────────────────────
# xss-lock with --transfer-sleep-lock locks the session before the machine sleeps
# (lid close / suspend key / loginctl). Skipped when xss-lock is already the idle
# locker, to avoid running two lockers.
idle_locker_is_xsslock() {
  [ "$IDLE_LOCK_MINUTES" -gt 0 ] 2>/dev/null \
    && ! command -v xidlehook >/dev/null 2>&1 \
    && ! command -v xautolock >/dev/null 2>&1
}
if [ "$LOCK_ON_SUSPEND" = 1 ] && command -v xss-lock >/dev/null 2>&1; then
  if ! idle_locker_is_xsslock; then
    xss-lock --transfer-sleep-lock -- "$LOCKER" & LOCK_PID=$!
  fi
fi

cleanup() {
  for pid in "$STATUS_PID" "$WALL_PID" "$DUNST_PID" "$PICOM_PID" "$IDLE_PID" "$LOCK_PID" "$CLIP_PID" "$BAT_PID"; do
    [ -z "$pid" ] || kill "$pid" 2>/dev/null || :
  done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

# NIRU autostart: run once dwm is up so apps land on their chosen workspace.
if [ -x "$HOME/.local/bin/nirupi-autostart.sh" ]; then
  (
    i=0
    while [ "$i" -lt 100 ]; do
      pgrep -u "$(id -u)" -x dwm >/dev/null 2>&1 && break
      sleep 0.2; i=$((i + 1))
    done
    sleep 1
    "$HOME/.local/bin/nirupi-autostart.sh" run
  ) >/dev/null 2>&1 &
fi

# Battery guard (laptops): warn/suspend on low battery.
if [ -x "$HOME/.local/bin/nirupi-battery.sh" ] && ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  "$HOME/.local/bin/nirupi-battery.sh" & BAT_PID=$!
fi

"$HOME/.local/bin/dwm"
