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
IDLE_LOCK_MINUTES="${IDLE_LOCK_MINUTES:-10}"
IDLE_WARN_SECONDS="${IDLE_WARN_SECONDS:-30}"
START_DUNST="${START_DUNST:-1}"
START_PICOM="${START_PICOM:-1}"

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

STATUS_PID= WALL_PID= DUNST_PID= PICOM_PID= IDLE_PID=
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
if command -v wallrotate.sh >/dev/null 2>&1; then
  if [ -d "${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}" ]; then
    wallrotate.sh & WALL_PID=$!
  fi
fi

# ── Automatic screen lock (slock) after inactivity ────────────────────────────
if [ "${IDLE_LOCK_MINUTES:-10}" -gt 0 ] 2>/dev/null; then
  idle_secs=$((IDLE_LOCK_MINUTES * 60))
  if command -v xidlehook >/dev/null 2>&1; then
    xidlehook --not-when-fullscreen --not-when-audio --timer "$idle_secs" '' slock & IDLE_PID=$!
  elif command -v xautolock >/dev/null 2>&1; then
    xautolock -time "$IDLE_LOCK_MINUTES" -locker slock -notify "$IDLE_WARN_SECONDS" \
      -notifier "notify-send -u normal 'NIRUPI' 'Skärmen låses om ${IDLE_WARN_SECONDS}s'" & IDLE_PID=$!
  elif command -v xss-lock >/dev/null 2>&1; then
    xset s "$idle_secs" "$idle_secs" 2>/dev/null || :
    xss-lock -- slock & IDLE_PID=$!
  else
    printf '%s\n' '[NIRUPI] No idle-lock tool found (xidlehook/xautolock/xss-lock)' >&2
  fi
fi

cleanup() {
  for pid in "$STATUS_PID" "$WALL_PID" "$DUNST_PID" "$PICOM_PID" "$IDLE_PID"; do
    [ -z "$pid" ] || kill "$pid" 2>/dev/null || :
  done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
"$HOME/.local/bin/dwm"
