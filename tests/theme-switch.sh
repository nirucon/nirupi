#!/usr/bin/env bash
# Switching the active theme must restyle every generated fragment (not just
# rofi/dunst/SDDM), so kitty/alacritty/fish/tmux/lazygit/micro/aerc/cmus follow.
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
BACKUP_DIR="$STATE/backups/theme-switch"; mkdir -p "$BACKUP_DIR"
export NIRUPI_NOIR_DIR="$ROOT/vendor/noir"

fail(){ echo "FAIL: $*" >&2; exit 1; }
read_bg(){ grep -m1 '^background' "$1" | awk '{print $2}'; }

# Every built-in theme resolves and applies.
for theme in noir Satie carl-larsson warm cool; do
  f="$(theme_palette_file "$theme")" || fail "unknown theme $theme"
  [[ -f $f ]] || fail "missing palette file for $theme"
done

theme_set Satie >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#1a1a1c' ]] || fail 'kitty not Satie'
grep -q '0x1a1a1c' "$HOME/.config/nirupi/theme/alacritty.toml" || fail 'alacritty not Satie'
grep -q '#1a1a1c' "$HOME/.config/aerc/stylesets/nirupi" || fail 'aerc not Satie'
grep -q '1a1a1c' "$HOME/.config/lazygit/config.yml" || fail 'lazygit not Satie'
grep -q '"#dcdcdc,#1a1a1c"' "$HOME/.config/micro/colorschemes/nirupi.micro" || fail 'micro not Satie'
grep -q 'colorscheme nirupi' "$HOME/.config/cmus/rc" || fail 'cmus rc missing'
grep -q 'set -g fish_color_normal dcdcdc' "$HOME/.config/nirupi/theme/fish.fish" || fail 'fish not Satie'
grep -q 'bg=#1a1a1c' "$HOME/.config/nirupi/theme/tmux.conf" || fail 'tmux not Satie'
grep -q 'NIRUPI_C_RED=b08a86' "$HOME/.config/nirupi/theme/status.env" || fail 'status accents not Satie'

theme_set carl-larsson >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#241a16' ]] || fail 'kitty not Carl Larsson'
grep -q '0x241a16' "$HOME/.config/nirupi/theme/alacritty.toml" || fail 'alacritty not Carl Larsson'

# Back to Noir restores the default background everywhere.
theme_set noir >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#0f0f10' ]] || fail 'noir not restored'

# Idempotency: re-applying the same theme is stable.
theme_apply >/dev/null
theme_apply >/dev/null
echo 'PASS: switching themes restyles terminals, TUI tools and launchers'

# Display names shown by the picker (and accepted by `nirupi theme set`) resolve,
# including the default theme whose display name is "Noir".
for name in Noir Satie "Carl Larsson" "Noir warm" "Noir cool" noir warm cool carl; do
  f="$(theme_palette_file "$name")" || fail "display name '$name' did not resolve"
  [[ -f $f ]] || fail "display name '$name' resolved to a missing file"
done
[[ "$(theme_palette_file Noir)" == */tokens.env ]] || fail 'Noir should resolve to tokens.env'
theme_set "Carl Larsson" >/dev/null || fail 'theme_set by display name failed'
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#241a16' ]] || fail 'display-name apply not Carl Larsson'
theme_set noir >/dev/null

# The runtime `nirupi theme` path sources the library without the installer's
# per-run BACKUP_DIR, so applying must derive one instead of aborting.
( unset BACKUP_DIR; theme_apply ) >/dev/null 2>&1 || fail 'theme_apply failed without BACKUP_DIR'
echo 'PASS: theme display names and BACKUP_DIR-free apply'

# A hand-edited lazygit config is preserved (with a proposal), never clobbered.
printf '# user edit\n' >> "$HOME/.config/lazygit/config.yml"
theme_set Satie >/dev/null
grep -q '# user edit' "$HOME/.config/lazygit/config.yml" || fail 'lazygit user edit was lost'
[[ -f "$HOME/.config/lazygit/config.yml.nirupi-new" ]] || fail 'lazygit proposal missing'
echo 'PASS: user-edited lazygit config preserved'
