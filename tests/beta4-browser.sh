#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"
mkdir -p "$HOME" "$tmp/bin"
cat > "$tmp/bin/helium" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$HOME/launch-args"
EOF
chmod +x "$tmp/bin/helium"
export PATH="$tmp/bin:/usr/bin:/bin"
[[ "$("$ROOT/runtime/nirupi-browser" status)" == $'Configured: auto\nResolved: helium' ]]
"$ROOT/runtime/nirupi-browser" launch 'https://example.com/a?b=1&c=2'
[[ "$(cat "$HOME/launch-args")" == 'https://example.com/a?b=1&c=2' ]]
"$ROOT/runtime/nirupi-browser" set helium
[[ "$("$ROOT/runtime/nirupi-browser" status)" == $'Configured: helium\nResolved: helium' ]]
if "$ROOT/runtime/nirupi-browser" set 'helium;touch /tmp/unsafe' 2>/dev/null; then exit 1; fi
"$ROOT/runtime/nirupi-browser" reset
[[ "$("$ROOT/runtime/nirupi-browser" status)" == $'Configured: auto\nResolved: helium' ]]
for cfg in config.h config.def.h; do
 grep -Fq 'static const char *browsercmd[] = { "nirupi-browser", NULL };' "$ROOT/vendor/suckless/dwm/$cfg"
done
grep -Fq 'managed_helper_install nirupi-browser' "$ROOT/lib/install.sh"
bash -n "$ROOT/runtime/nirupi-browser" "$ROOT/runtime/nirupi" "$ROOT/lib/install.sh" "$ROOT/install.sh"
echo 'PASS: beta.4 browser detection, launch, config, reset, safety, DWM integration'
