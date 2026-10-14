#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/home/.local/state" XDG_CONFIG_HOME="$TMP/home/.config"
mkdir -p "$HOME"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/managed.sh"
source "$ROOT/lib/theme.sh"
mkdir -p "$STATE"
BACKUP_DIR="$STATE/backups/theme"; mkdir -p "$BACKUP_DIR"
NIRUPI_NOIR_DIR="$ROOT/vendor/noir" theme_apply

for f in \
  .config/kitty/kitty.conf .config/alacritty/alacritty.toml .config/fish/config.fish \
  .config/tmux/tmux.conf .config/lazygit/config.yml .config/micro/settings.json \
  .config/aerc/aerc.conf .config/brave-flags.conf .config/chromium-flags.conf \
  .config/environment.d/90-nirupi.conf .config/gtk-4.0/settings.ini \
  .config/nirupi/xresources.noir; do
  [[ -f "$HOME/$f" ]] || { echo "FAIL missing $f" >&2; exit 1; }
done

# Token source of truth
theme_load_tokens
[[ "$NOIR_BG" == 0f0f10 && "$NOIR_FG" == e5e5e5 ]]

# Dark environment exported for GTK/Qt/terminals
envd="$HOME/.config/environment.d/90-nirupi.conf"
grep -q '^GTK_THEME=Adwaita:dark$' "$envd"
grep -q '^QT_STYLE_OVERRIDE=kvantum$' "$envd"
grep -q '^COLORTERM=truecolor$' "$envd"
grep -q -- '--force-dark-mode' "$HOME/.config/brave-flags.conf"
grep -q 'gtk-theme-name=Adwaita-dark' "$HOME/.config/gtk-4.0/settings.ini"

# Session runtime exports the dark theme and uses the Noir background.
grep -q 'QT_STYLE_OVERRIDE=kvantum' "$ROOT/runtime-session.sh"
grep -q "GTK_THEME=\"Adwaita:dark\"" "$ROOT/runtime-session.sh"
grep -q "COLORTERM=truecolor" "$ROOT/runtime-session.sh"
grep -q "xsetroot -solid '#0f0f10'" "$ROOT/runtime-session.sh"
grep -q 'command -v picom' "$ROOT/runtime-session.sh"

# Idempotent second run
theme_apply

# User edits are preserved and receive a proposal.
printf '# my edit\n' >> "$HOME/.config/tmux/tmux.conf"
theme_apply
grep -q '# my edit' "$HOME/.config/tmux/tmux.conf"
[[ -f "$HOME/.config/tmux/tmux.conf.nirupi-new" ]]

# Diff report runs read-only.
NIRUPI_NOIR_DIR="$ROOT/vendor/noir" theme_diff >/dev/null
echo 'PASS: Noir theme engine, dark environment, idempotency and preservation'
