#!/usr/bin/env bash
# Switching the active theme must restyle every generated fragment (not just
# rofi/dunst/SDDM), so kitty/alacritty/fish/tmux/lazygit/micro/aerc/cmus follow.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export NIRUPI_NO_NOTIFY=1   # tests must never pop desktop notifications
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
for theme in noir Satie carl-larsson hackerman nord-dark noir-day warm cool; do
  f="$(theme_palette_file "$theme")" || fail "unknown theme $theme"
  [[ -f $f ]] || fail "missing palette file for $theme"
done

# The Noir variants must be listed (they used to be hidden from the picker).
theme_names_out="$(theme_names)"
grep -qx 'Noir-warm' <<< "$theme_names_out" || fail 'Noir-warm not listed'
grep -qx 'Noir-cool' <<< "$theme_names_out" || fail 'Noir-cool not listed'

# `nirupi theme list` must show every theme with its display name.
list_out="$(theme_list)"
for want in Noir Hackerman "Nord dark" "Noir day" Satie "Carl Larsson" "Noir warm"; do
  grep -q "$want" <<< "$list_out" || fail "theme list missing $want"
done

theme_set Satie >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#232326' ]] || fail 'kitty not Satie'
grep -q '0x232326' "$HOME/.config/nirupi/theme/alacritty.toml" || fail 'alacritty not Satie'
grep -q '#232326' "$HOME/.config/aerc/stylesets/nirupi" || fail 'aerc not Satie'
grep -q '232326' "$HOME/.config/lazygit/config.yml" || fail 'lazygit not Satie'
grep -q '"#e6e6e6,#232326"' "$HOME/.config/micro/colorschemes/nirupi.micro" || fail 'micro not Satie'
grep -q 'colorscheme nirupi' "$HOME/.config/cmus/rc" || fail 'cmus rc missing'
grep -q 'set -g fish_color_normal e6e6e6' "$HOME/.config/nirupi/theme/fish.fish" || fail 'fish not Satie'
grep -q 'bg=#232326' "$HOME/.config/nirupi/theme/tmux.conf" || fail 'tmux not Satie'
grep -q 'NIRUPI_C_RED=a89a97' "$HOME/.config/nirupi/theme/status.env" || fail 'status accents not Satie'
grep -q 'corner-radius = 0' "$HOME/.config/picom/picom.conf" || fail 'picom not generated (no rounded corners)'
grep -q 'generated from tokens.env' "$HOME/.config/picom/picom.conf" || fail 'picom not themed'
grep -q 'background = "#232326"' "$HOME/.config/dunst/dunstrc.d/90-nirupi.conf" || fail 'dunst drop-in not Satie'

theme_set carl-larsson >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#241a16' ]] || fail 'kitty not Carl Larsson'
grep -q '0x241a16' "$HOME/.config/nirupi/theme/alacritty.toml" || fail 'alacritty not Carl Larsson'

theme_set hackerman >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#0a0f0a' ]] || fail 'kitty not Hackerman'
grep -q 'set -g fish_color_normal b6f2b6' "$HOME/.config/nirupi/theme/fish.fish" || fail 'fish not Hackerman'

theme_set nord-dark >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#2e3440' ]] || fail 'kitty not Nord dark'
grep -q '0x2e3440' "$HOME/.config/nirupi/theme/alacritty.toml" || fail 'alacritty not Nord dark'

theme_set noir-day >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#f4f1ea' ]] || fail 'kitty not Noir day'
grep -q 'set -g fish_color_normal 2f2c27' "$HOME/.config/nirupi/theme/fish.fish" || fail 'fish not Noir day'

# Back to Noir restores the default background everywhere.
theme_set noir >/dev/null
[[ "$(read_bg "$HOME/.config/nirupi/theme/kitty.conf")" == '#0f0f10' ]] || fail 'noir not restored'

# Idempotency: re-applying the same theme is stable.
theme_apply >/dev/null
theme_apply >/dev/null
echo 'PASS: switching themes restyles terminals, TUI tools and launchers'

# Display names shown by the picker (and accepted by `nirupi theme set`) resolve,
# including the default theme whose display name is "Noir".
for name in Noir Satie "Carl Larsson" Hackerman "Nord dark" "Noir day" "Noir warm" "Noir cool" noir warm cool carl hackerman nord-dark noir-day; do
  f="$(theme_palette_file "$name")" || fail "display name '$name' did not resolve"
  [[ -f $f ]] || fail "display name '$name' resolved to a missing file"
done
[[ "$(theme_palette_file Noir)" == */tokens.env ]] || fail 'Noir should resolve to tokens.env'

# A pre-0.8 palette file (no NOIR_THEME_NAME) is identified by its background.
printf 'NOIR_BG=120f0d\nNOIR_FG=e8e2d8\n' > "$HOME/.config/nirupi/tokens.env"
[[ "$(theme_current)" == 'Noir warm' ]] || fail 'stale palette not identified by background'
rm -f "$HOME/.config/nirupi/tokens.env"

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

# The user's dunst base config is preserved; colours live in the drop-in.
printf '# my dunst tweak\n' >> "$HOME/.config/dunst/dunstrc"
theme_set Satie >/dev/null
grep -q '# my dunst tweak' "$HOME/.config/dunst/dunstrc" || fail 'dunst base edit was lost'
[[ -f "$HOME/.config/dunst/dunstrc.nirupi-new" ]] || fail 'dunst proposal missing'
grep -q 'background = "#232326"' "$HOME/.config/dunst/dunstrc.d/90-nirupi.conf" || fail 'dunst drop-in not themed'
echo 'PASS: dunst settings preserved, colours themed via drop-in'
