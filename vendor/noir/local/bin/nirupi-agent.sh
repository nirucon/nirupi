#!/usr/bin/env bash
# NIRUPI agent launcher — opens opencode (AI coding agent) in a terminal.
#   nirupi-agent.sh                pick a profile (rofi/dmenu) then launch
#   nirupi-agent.sh <profile>      launch a named profile directly
# Profiles live in ~/.config/nirupi/agents.conf (name|command).
set -Eeuo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/nirupi/agents.conf"
TERM_BIN="$(command -v kitty || command -v alacritty || command -v st || true)"
command -v opencode >/dev/null 2>&1 || { printf 'opencode not installed\n' >&2; }

ensure_conf(){
  [[ -f "$CONF" ]] && return 0
  [[ -L "$CONF" ]] && return 1
  mkdir -p "$(dirname "$CONF")"
  cat > "$CONF" <<'EOF'
# NIRUPI agent profiles: name|command (run inside a terminal in the cwd).
default|opencode
deepseek|opencode --model deepseek/deepseek-chat
codex|opencode --model openai/gpt-5-codex
claude|opencode --model anthropic/claude-sonnet-4
EOF
}
ensure_conf || true

pick(){
  local lines
  lines="$(awk -F'|' '/^[[:space:]]*[^#]/ && NF>=2 {printf "%s  ->  %s\n", $1, $2}' "$CONF")"
  [[ -n "$lines" ]] || return 0
  if command -v rofi >/dev/null 2>&1; then printf '%s\n' "$lines" | rofi -dmenu -i -p 'Agent';
  elif command -v dmenu >/dev/null 2>&1; then printf '%s\n' "$lines" | dmenu -i -p 'Agent';
  else printf '%s\n' "$lines"; fi
}

resolve(){
  local name="$1"
  awk -F'|' -v n="$name" '/^[[:space:]]*[^#]/ {gsub(/^[ \t]+|[ \t]+$/,"",$1); if ($1==n){print $2; exit}}' "$CONF"
}

profile="${1:-}"
if [[ -z "$profile" ]]; then
  sel="$(pick)" || true
  [[ -n "${sel:-}" ]] || exit 0
  profile="${sel%%  ->*}"
fi
cmd="$(resolve "$profile")"
[[ -n "$cmd" ]] || cmd="$profile"   # allow passing a raw command

[[ -n "$TERM_BIN" ]] || { printf 'No terminal found for agent\n' >&2; exit 1; }
exec "$TERM_BIN" --title "NIRUPI Agent" -e bash -lc "$cmd"
