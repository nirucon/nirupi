#!/usr/bin/env bash
# Status-bar pop-up: pending updates panel, then a confirmation before starting
# the upgrade. Distro-aware (Arch/pacman, Debian/apt, Void/xbps); AUR is listed
# on Arch when a helper is present.
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
have(){ command -v "$1" >/dev/null 2>&1; }
notify(){ if have notify-send; then notify-send -a NIRUPI "Updates" "$1"; else printf 'Updates: %s\n' "$1"; fi; }
pick(){ if have rofi; then rofi -dmenu -i -p 'Updates'; elif have dmenu; then dmenu -i -p 'Updates'; else head -n1; fi; }

. /etc/os-release 2>/dev/null || true
distro="${ID:-unknown}"
idlike="${ID_LIKE:-}"

pending(){ # prints "name version" lines (or name only) for the native manager
  case "$distro $idlike" in
    *arch*)
      if have checkupdates; then checkupdates 2>/dev/null; else pacman -Qu 2>/dev/null; fi;;
    *debian*|*ubuntu*)
      LC_ALL=C apt list --upgradable 2>/dev/null | awk -F/ 'NR>1{print $1}';;
    *void*) xbps-install -un 2>/dev/null;;
    *) :;;
  esac
}
aur_pending(){ # Arch only
  case "$distro $idlike" in *arch*|*cachyos*) :;; *) return 0;; esac
  if have paru; then paru -Qua 2>/dev/null | awk '{print $1}'
  elif have yay; then yay -Qua 2>/dev/null | awk '{print $1}'; fi
}

case "$distro" in
  arch|cachyos) mgr="pacman -Syu";;
  debian|ubuntu) mgr="apt full-upgrade";;
  void) mgr="xbps-install -Syu";;
  *) mgr="(unknown package manager)";;
esac

_tmp_native="$(mktemp)"; _tmp_aur="$(mktemp)"
pending  >"$_tmp_native" 2>/dev/null || true
aur_pending >"$_tmp_aur" 2>/dev/null || true
mapfile -t pkgs < <(awk 'NF' "$_tmp_native")
mapfile -t aur  < <(awk 'NF' "$_tmp_aur")
rm -f "$_tmp_native" "$_tmp_aur"
total=$(( ${#pkgs[@]} + ${#aur[@]} ))
last="$(date -r "${XDG_CACHE_HOME:-$HOME/.cache}/dwm-status/updates.stamp" '+%Y-%m-%d %H:%M' 2>/dev/null || true)"

accent=cyan; (( total > 0 )) && accent=yellow
spec="$(
  printf '@title Updates\n'
  printf '@sub %s — %s\n' "$(cat /etc/hostname 2>/dev/null || uname -n)" "${distro}"
  printf '@accent %s\n' "$accent"
  if (( total == 0 )); then
    printf '@note Everything is up to date.\n'
    [[ -n $last ]] && printf '@note Last checked %s\n' "$last"
  else
    (( ${#pkgs[@]} > 0 )) && printf '@note Official packages: %s\n' "${#pkgs[@]}"
    (( ${#aur[@]} > 0 )) && printf '@note AUR packages: %s\n' "${#aur[@]}"
    printf '@note \342\224\200\342\224\200 packages \342\224\200\342\224\200\n'
    for p in "${pkgs[@]:0:12}"; do printf '@row %s|\n' "${p%% *}"; done
    (( ${#pkgs[@]} > 12 )) && printf '@note … and %s more\n' "$(( ${#pkgs[@]} - 12 ))"
    for p in "${aur[@]:0:8}"; do printf '@row %s|AUR\n' "${p%% *}"; done
    # One window: the choice lives in the panel. Enter runs the default.
    printf '@choice y|Upgrade now  (sudo %s)\n' "$mgr"
    printf '@cancel q|Cancel\n'
  fi
)"

if (( total == 0 )); then
  printf '%s\n' "$spec" | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Updates >/dev/null 2>&1 || true
  exit 0
fi

ans="$(printf '%s\n' "$spec" | NIRUPI_POPUP=tui "$HOME/.local/bin/nirupi-popup.sh" Updates 2>/dev/null || true)"
case "$ans" in
  y*) exec "$HOME/.local/bin/nirupi-sysupdate.sh";;
  *) notify 'Upgrade cancelled';;
esac
