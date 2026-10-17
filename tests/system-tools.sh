#!/usr/bin/env bash
# New maintenance tools: profiles, tune, snapshot, explain, mission, backup.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home" XDG_STATE_HOME="$TMP/state" XDG_CONFIG_HOME="$TMP/home/.config"
mkdir -p "$HOME/.config/nirupi"

# Profiles: minimal excludes apps, full enables the optional set.
[[ "$("$ROOT/tools/package-list.sh" debian base | grep -c '^alacritty$' || true)" -ge 1 ]] || fail 'desktop profile lost alacritty'
NIRUPI_PROFILE=minimal "$ROOT/tools/package-list.sh" debian base | grep -qx alacritty && fail 'minimal profile still includes alacritty'
NIRUPI_PROFILE=full "$ROOT/tools/package-list.sh" debian optional | grep -qx gimp || fail 'full profile has no optional apps'

# Tune plan is read-only and mentions the generated file.
"$ROOT/vendor/noir/local/bin/nirupi-tune.sh" plan > "$TMP/tune" || fail 'tune plan failed'
grep -q 'Would write /etc/sysctl.d/90-nirupi.conf' "$TMP/tune" || fail 'tune plan incomplete'
[[ ! -e /etc/sysctl.d/90-nirupi.conf ]] || true

# Snapshot status must work without a backend.
"$ROOT/vendor/noir/local/bin/nirupi-snapshot.sh" status > "$TMP/snap" || fail 'snapshot status failed'
grep -q 'Root filesystem' "$TMP/snap" || fail 'snapshot status output missing'

# Explain --print must not need a model.
"$ROOT/vendor/noir/local/bin/nirupi-explain.sh" --print > "$TMP/explain" || fail 'explain --print failed'
grep -q 'NIRUPI health context' "$TMP/explain" || fail 'explain context missing'

# Missions: list from the example.
cp "$ROOT/runtime/missions.conf.example" "$HOME/.config/nirupi/missions.conf"
"$ROOT/vendor/noir/local/bin/nirupi-mission.sh" --list > "$TMP/mission" || fail 'mission list failed'
grep -q '^work ' "$TMP/mission" || fail 'mission list missing work'

# Backup: create, verify, restore and prune.
mkdir -p "$HOME/.config/nirupi"; printf 'keep\n' > "$HOME/.config/nirupi/test.conf"
"$ROOT/vendor/noir/local/bin/nirupi-backup.sh" --now >/dev/null || fail 'backup --now failed'
archive="$(find "$XDG_STATE_HOME/nirupi/backups" -name 'nirupi-config-*.tar.gz' | head -1)"
[[ -n $archive ]] || fail 'backup archive missing'
"$ROOT/vendor/noir/local/bin/nirupi-backup.sh" --verify "$archive" | grep -q '^OK:' || fail 'backup --verify failed'
printf 'changed\n' > "$HOME/.config/nirupi/test.conf"
"$ROOT/vendor/noir/local/bin/nirupi-backup.sh" --restore "$archive" --yes >/dev/null || fail 'backup --restore failed'
grep -qx keep "$HOME/.config/nirupi/test.conf" || fail 'restore did not restore content'

# gc --system is a dry-run plan unless --yes.
"$ROOT/runtime/nirupi-gc.sh" --dry-run --system > "$TMP/gc" || fail 'gc --system dry-run failed'
grep -q 'System cleanup' "$TMP/gc" || fail 'gc --system plan missing'
echo 'PASS: profiles, tune, snapshot, explain, missions, backup and system gc'
