#!/usr/bin/env bash
# Upgrading from an older/untracked install must be able to adopt the new
# bundled scripts. `--update-dots` refreshes NIRUPI helpers (with backups)
# and re-applies the theme, without touching system packages or rebuilding dwm.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/home/.local/state" XDG_CONFIG_HOME="$TMP/home/.config" NIRUPI_NO_RESTART=1
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\n# OLD nirupi status\n' > "$HOME/.local/bin/dwm-status.sh"
printf '#!/usr/bin/env bash\n# OLD nirupi cli\n' > "$HOME/.local/bin/nirupi"

bash "$ROOT/install.sh" --update-dots >/dev/null 2>&1

grep -q 'icon_agent' "$HOME/.local/bin/dwm-status.sh" || { echo 'FAIL statusbar not adopted' >&2; exit 1; }
grep -q 'agent) exec' "$HOME/.local/bin/nirupi" || { echo 'FAIL nirupi cli not adopted' >&2; exit 1; }
[[ -x "$HOME/.local/bin/nirupi-status-click.sh" ]] || { echo 'FAIL new helper missing' >&2; exit 1; }
find "$XDG_STATE_HOME/nirupi/backups" -name 'dwm-status.sh' 2>/dev/null | grep -q . || { echo 'FAIL no backup kept' >&2; exit 1; }
[[ -f "$HOME/.config/nirupi/xresources.noir" ]] || { echo 'FAIL theme xresources missing' >&2; exit 1; }
echo 'PASS: --update-dots adopts new helpers with backups and reapplies theme'
