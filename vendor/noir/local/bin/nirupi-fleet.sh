#!/usr/bin/env bash
# Read-only status across the hosts listed in ~/.config/nirupi/fleet.conf (one
# per line; blank lines and #comments ignored). No sudo. Needs SSH keys
# (BatchMode); without them a host is reported as unreachable.
set -Eeuo pipefail
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/fleet.conf"
if [[ ! -r $conf ]]; then
  printf 'No fleet config at %s\n' "$conf"
  printf 'Create it with one host per line, e.g.:\n  othala\n  void\n'
  exit 0
fi
remote='export PATH="$HOME/.local/bin:$PATH"; h=$(cat /etc/hostname 2>/dev/null || uname -n); v=$(cat "$HOME/.local/lib/nirupi/VERSION" 2>/dev/null || echo -); s=$([ -n "$(pgrep -f nirupi-session 2>/dev/null)" ] && echo nirupi || echo other); u=$(nirupi-updates 2>/dev/null | tr -dc "0-9" | head -c4); printf "%s|%s|%s" "$v" "$s" "${u:-0}"'
printf '%-12s %-9s %-8s %s\n' HOST VERSION SESSION UPDATES
while IFS= read -r host; do
  host="${host%%#*}"; host="$(printf '%s' "$host" | tr -d '[:space:]')"
  [[ -n $host ]] || continue
  out="$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$host" "$remote" 2>/dev/null || true)"
  if [[ -z $out ]]; then
    printf '%-12s %s\n' "$host" 'unreachable / needs SSH key'
    continue
  fi
  IFS='|' read -r v s u <<<"$out"
  printf '%-12s %-9s %-8s %s\n' "$host" "${v:--}" "${s:--}" "${u:--}"
done < "$conf"
