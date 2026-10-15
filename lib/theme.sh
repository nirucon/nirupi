#!/usr/bin/env bash
# NIRU Noir theme engine.
# Applies the unified dark theme from a single token source to terminals,
# shells, TUI tools, browsers and GTK/Qt. Never overwrites user-modified
# files: all writes go through managed_config_install (three-way merge).
# Sourced after lib/common.sh and lib/managed.sh.

# Resolve the directory holding the bundled Noir assets.
noir_dir(){
  if [[ -n ${NIRUPI_NOIR_DIR:-} ]]; then printf '%s' "$NIRUPI_NOIR_DIR"; return; fi
  if [[ -n ${ROOT:-} && -d "$ROOT/vendor/noir" ]]; then printf '%s' "$ROOT/vendor/noir"; return; fi
  if [[ -d "$HOME/.local/lib/nirupi/noir" ]]; then printf '%s' "$HOME/.local/lib/nirupi/noir"; return; fi
  printf '%s' "$HOME/.local/lib/nirupi/noir"
}

# Resolve the directory holding the bundled SDDM theme (vendor/sddm).
sddm_dir(){
  if [[ -n ${NIRUPI_SDDM_DIR:-} ]]; then printf '%s' "$NIRUPI_SDDM_DIR"; return; fi
  if [[ -n ${ROOT:-} && -d "$ROOT/vendor/sddm" ]]; then printf '%s' "$ROOT/vendor/sddm"; return; fi
  printf '%s' "$HOME/.local/lib/nirupi/sddm"
}

# User configuration directory (honors XDG_CONFIG_HOME).
cfgdir(){ printf '%s' "${XDG_CONFIG_HOME:-${HOME}/.config}"; }

# Directory holding the generated (NIRUPI-owned) per-app colour fragments.
# These files are always rewritten by `nirupi theme apply`; user app configs
# only *include* them, so a palette switch never fights three-way merging.
theme_gen_dir(){ printf '%s/nirupi/theme' "$(cfgdir)"; }

# Atomically write generated content (stdin) to a NIRUPI-owned path. Symlinks
# and non-regular files are preserved, never followed. $2 = mode (default 0644).
theme_generate(){
  local dest="$1" mode="${2:-0644}" tmp
  if [[ -L $dest ]]; then warn "Preserving symlinked $dest"; cat >/dev/null; return 0; fi
  if [[ -e $dest && ! -f $dest ]]; then warn "Preserving non-regular $dest"; cat >/dev/null; return 0; fi
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$(dirname "$dest")/.nirupi-gen.XXXXXXXX")"
  if ! cat > "$tmp"; then rm -f -- "$tmp"; return 1; fi
  chmod "$mode" "$tmp"
  mv -f -- "$tmp" "$dest"
}

theme_tokens_file(){
  if [[ -n ${NIRUPI_TOKENS_FILE:-} && -f $NIRUPI_TOKENS_FILE ]]; then printf '%s' "$NIRUPI_TOKENS_FILE"; return; fi
  local user="$(cfgdir)/nirupi/tokens.env"
  if [[ -f $user && ! -L $user ]]; then printf '%s' "$user"; return; fi
  printf '%s/theme/tokens.env' "$(noir_dir)"
}

theme_load_tokens(){
  local f; f="$(theme_tokens_file)"
  [[ -f $f && ! -L $f ]] || die "Missing theme token source: $f"
  # shellcheck disable=SC1090
  source "$f"
  # Per-theme metadata (optional in a palette file; sane defaults otherwise).
  : "${NOIR_THEME_NAME:=noir}"
  : "${NOIR_THEME_DESC:=NIRU Noir}"
  : "${NOIR_GTK_THEME:=Adwaita:dark}"
  : "${NOIR_GTK4_THEME:=Adwaita-dark}"
}

# Read one variable from a palette file without polluting the current shell.
palette_field(){
  local f="$1" v="$2" k
  [[ -f $f && ! -L $f ]] || return 0
  (
    set +u
    # Never let an already-set NOIR_* variable (e.g. from an earlier
    # theme_load_tokens) leak into a palette file that does not define it.
    for k in ${!NOIR_@}; do unset "$k"; done
    # shellcheck disable=SC1090
    source "$f" >/dev/null 2>&1 || true
    printf '%s' "${!v:-}"
  )
}

# Read NOIR_THEME_NAME from a palette file.
palette_name(){ palette_field "$1" NOIR_THEME_NAME; }

# Theme configuration directories that live under ~/.config. The bundled
# dunstrc is deployed as the *base* config; its colours come from a generated
# drop-in (see theme_render_dunst), which outranks the base in dunst.
NIRUPI_THEME_APPS=(kitty alacritty fish tmux lazygit micro aerc rofi cmus dunst)

theme_apply_configs(){
  local noir="$1" app src dest
  for app in "${NIRUPI_THEME_APPS[@]}"; do
    [[ -d $noir/config/$app ]] || continue
    if [[ -L $(cfgdir)/$app ]]; then warn "Preserving symlink ~/.config/$app"; continue; fi
    if [[ -e $(cfgdir)/$app && ! -d $(cfgdir)/$app ]]; then
      warn "Preserving non-directory config path ~/.config/$app"; continue
    fi
    mkdir -p "$(cfgdir)/$app"
    while IFS= read -r -d '' src; do
      [[ $(basename "$src") == fish_variables ]] && continue
      dest="$(cfgdir)/$app/${src#"$noir/config/$app/"}"
      managed_config_install "config/$app/${src#"$noir/config/$app/"}" "$src" "$dest"
    done < <(find "$noir/config/$app" -type f -print0)
  done
}

theme_apply_browser_flags(){
  local noir="$1" flags name dest
  flags="$noir/config/brave-flags.conf"
  [[ -f $flags ]] || return 0
  for name in brave-flags.conf helium-flags.conf chromium-flags.conf; do
    dest="$(cfgdir)/$name"
    managed_config_install "config/$name" "$flags" "$dest"
  done
  if command -v brave >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1; then
    log 'Brave dark-mode flags installed (~/.config/brave-flags.conf)'
  fi
}

theme_apply_environment(){
  local dest="$(cfgdir)/environment.d/90-nirupi.conf" tmp
  [[ -L $(cfgdir)/environment.d ]] && { warn 'Preserving symlinked environment.d'; return 0; }
  mkdir -p "$(cfgdir)/environment.d"
  if [[ -e $dest && ! -f $dest ]]; then warn "Preserving non-regular $dest"; return 0; fi
  tmp="$(mktemp "$(cfgdir)/environment.d/.nirupi-env.XXXXXXXX")"
  {
    printf '# Generated by NIRUPI — dark session defaults for the active theme.\n'
    printf 'GTK_THEME=%s\n' "${NOIR_GTK_THEME:-Adwaita:dark}"
    printf 'QT_QPA_PLATFORMTHEME=qt5ct\n'
    printf 'QT_STYLE_OVERRIDE=kvantum\n'
    printf 'XCURSOR_THEME=Adwaita\n'
    printf 'COLORTERM=truecolor\n'
  } > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$dest"
  log "Wrote $dest"
}

theme_apply_gtk4(){
  local dest="$(cfgdir)/gtk-4.0/settings.ini" tmp
  [[ -L $(cfgdir)/gtk-4.0 ]] && { warn 'Preserving symlinked gtk-4.0'; return 0; }
  mkdir -p "$(cfgdir)/gtk-4.0"
  if [[ -e $dest && ! -f $dest ]]; then warn "Preserving non-regular $dest"; return 0; fi
  tmp="$(mktemp "$(cfgdir)/gtk-4.0/.nirupi-gtk4.XXXXXXXX")"
  if [[ -f $dest ]]; then cp -p -- "$dest" "$tmp"; else printf '[Settings]\n' > "$tmp"; fi
  local gtk="${NOIR_GTK4_THEME:-Adwaita-dark}"
  if grep -q '^gtk-theme-name=' "$tmp"; then
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk/" "$tmp"
  else
    printf 'gtk-theme-name=%s\n' "$gtk" >> "$tmp"
  fi
  local icons="${NOIR_ICON_THEME:-}"
  if [[ -z $icons ]]; then
    icons="Adwaita"
    for _t in Papirus-Dark Tela-black Tela-circle-black; do
      [[ -d "/usr/share/icons/$_t" || -d "$HOME/.local/share/icons/$_t" ]] && { icons="$_t"; break; }
    done
  fi
  if grep -q '^gtk-icon-theme-name=' "$tmp"; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icons/" "$tmp"
  else
    printf 'gtk-icon-theme-name=%s\n' "$icons" >> "$tmp"
  fi
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$dest"
}

# Install bundled fonts (e.g. Noto Sans Runic for the lock screensaver).
theme_install_fonts(){
  local noir; noir="$(noir_dir)"
  [[ -d $noir/fonts ]] || return 0
  [[ -L $HOME/.local/share/fonts ]] && { warn 'Preserving symlinked fonts dir'; return 0; }
  local dest="$HOME/.local/share/fonts/nirupi" f changed=0
  mkdir -p "$dest"
  for f in "$noir"/fonts/*; do
    [[ -f $f && ! -L $f ]] || continue
    if [[ ! -f $dest/$(basename "$f") ]] || ! cmp -s -- "$f" "$dest/$(basename "$f")"; then
      cp -f -- "$f" "$dest/$(basename "$f")"; changed=1
    fi
  done
  if (( changed )) && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$dest" >/dev/null 2>&1 || :
  fi
}

# ── Generated assets (rofi, dunst, SDDM) — produced from tokens.env ──────────
# Rofi theme is regenerated from the palette so it always matches the active
# theme (tokens.env), instead of the static Black-Metal.rasi.
theme_render_rofi(){
  local dest="$HOME/.local/share/rofi/themes/Black-Metal.rasi" tmp altbg
  altbg="$(_hex_mix "$NOIR_BG" "$NOIR_FG" 6)"
  [[ -L $HOME/.local/share/rofi ]] && { warn 'Preserving symlinked rofi dir'; return 0; }
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$(dirname "$dest")/.nirupi-rofi.XXXXXXXX")"
  {
    printf '/************************************************\n'
    printf ' * ROFI color theme — NIRU Noir (generated)\n'
    printf ' * Generated by NIRUPI from tokens.env. Re-run: nirupi theme apply\n'
    printf ' ***********************************************/\n\n'
    printf '* {\n'
    printf '    background:                  #%s;\n' "$NOIR_BG"
    printf '    background-color:            #%s;\n' "$NOIR_BG"
    printf '    foreground:                  #%s;\n' "$NOIR_FG"
    printf '    text-color:                  #%s;\n' "$NOIR_FG"
    printf '    normal-background:           @background;\n'
    printf '    normal-foreground:           @foreground;\n'
    printf '    alternate-normal-background: #%s;\n' "$altbg"
    printf '    alternate-normal-foreground: @foreground;\n'
    printf '    selected-normal-background:  #%s;\n' "$NOIR_SELECTION"
    printf '    selected-normal-foreground:  #%s;\n' "$NOIR_FG"
    printf '    active-background:           #%s;\n' "$NOIR_SELECTION"
    printf '    active-foreground:           #%s;\n' "$NOIR_FG"
    printf '    urgent-background:           #%s;\n' "$NOIR_BG"
    printf '    urgent-foreground:           #%s;\n' "$NOIR_ANSI_9"
    printf '    border-color:                #%s;\n' "$NOIR_BORDER"
    printf '    separatorcolor:              #%s;\n' "$NOIR_BORDER"
    printf '    spacing: 0;\n'
    printf '}\n\n'
    printf 'window { background-color: @background; border: 1; border-color: @border-color; padding: 6px; }\n'
    printf 'mainbox { background-color: transparent; border: 0; padding: 0; }\n'
    printf 'message { border: 1px 0 0; border-color: @separatorcolor; padding: 2px; text-color: @foreground; }\n'
    printf 'textbox { background-color: transparent; text-color: @foreground; }\n'
    printf 'listview { background-color: transparent; border: 1px 0 0; border-color: @separatorcolor; spacing: 2px; scrollbar: true; padding: 2px 0 0; }\n'
    printf 'element { background-color: transparent; border: 0; padding: 4px; }\n'
    printf 'element-text { background-color: transparent; text-color: @normal-foreground; }\n'
    printf 'element-icon { background-color: transparent; text-color: @normal-foreground; size: 1em; }\n'
    printf 'element normal.normal { background-color: @normal-background; text-color: @normal-foreground; }\n'
    printf 'element alternate.normal { background-color: @alternate-normal-background; text-color: @alternate-normal-foreground; }\n'
    printf 'element selected.normal { background-color: @selected-normal-background; text-color: @selected-normal-foreground; }\n'
    printf 'element normal.urgent { background-color: @urgent-background; text-color: @urgent-foreground; }\n'
    printf 'element selected.urgent { background-color: @selected-normal-background; text-color: @urgent-foreground; }\n'
    printf 'inputbar { children: [ prompt, textbox-prompt-colon, entry, case-indicator ]; background-color: transparent; padding: 4px; }\n'
    printf 'prompt { background-color: transparent; text-color: @normal-foreground; }\n'
    printf 'textbox-prompt-colon { background-color: transparent; text-color: @normal-foreground; expand: false; str: ":"; }\n'
    printf 'entry { background-color: transparent; text-color: @normal-foreground; }\n'
    printf 'case-indicator { background-color: transparent; text-color: @normal-foreground; }\n'
    printf 'button { background-color: transparent; text-color: @normal-foreground; }\n'
    printf 'button.selected { background-color: @selected-normal-background; text-color: @selected-normal-foreground; }\n'
    printf 'scrollbar { border: 0; width: 6px; handle-color: #%s; handle-width: 8px; }\n' "$NOIR_FOCUS"
    printf 'mode-switcher { background-color: transparent; border: 1px 0 0; border-color: @separatorcolor; }\n'
  } > "$tmp"
  chmod 0644 "$tmp"
  managed_config_install 'rofi/Black-Metal.rasi' "$tmp" "$dest" 0644
  rm -f -- "$tmp"
}

# Dunst colour fragment. Dunst >= 1.8 reads drop-ins from dunstrc.d/*.conf
# which outrank the base dunstrc, so the theme only generates the colours and
# the user's own notification settings (padding, stacking, icon prefs, ...) are
# left untouched. The base config is deployed by theme_apply_configs.
theme_render_dunst(){
  local dest="$(cfgdir)/dunst/dunstrc.d/90-nirupi.conf"
  [[ -L $(cfgdir)/dunst ]] && { warn 'Preserving symlinked dunst dir'; return 0; }
  {
    printf '# Generated by NIRUPI from tokens.env. Re-run: nirupi theme apply\n'
    printf '[global]\n'
    printf '    font = %s %s\n' "$NOIR_FONT" "${NOIR_DUNST_SIZE:-10}"
    printf '    frame_color = "#%s"\n' "$NOIR_BORDER"
    printf '    separator_color = "#%s"\n' "$NOIR_BORDER"
    printf '\n[urgency_low]\n    background = "#%s"\n    foreground = "#%s"\n    frame_color = "#%s"\n    timeout = 5\n\n' \
      "$NOIR_BG" "$NOIR_MUTED" "$NOIR_BORDER"
    printf '[urgency_normal]\n    background = "#%s"\n    foreground = "#%s"\n    frame_color = "#%s"\n    timeout = 7\n\n' \
      "$NOIR_BG" "$NOIR_FG" "$NOIR_BORDER"
    printf '[urgency_critical]\n    background = "#%s"\n    foreground = "#%s"\n    frame_color = "#%s"\n    timeout = 0\n' \
      "$NOIR_BG" "$NOIR_ANSI_9" "$NOIR_ANSI_1"
  } | theme_generate "$dest"
}

# picom: compositor colours from the palette (tinted shadow, palette-driven
# opacity/fading). No rounded corners (corner-radius = 0).
theme_render_picom(){
  local dest="$(cfgdir)/picom/picom.conf"
  [[ -L $(cfgdir)/picom ]] && { warn 'Preserving symlinked ~/.config/picom'; return 0; }
  cat <<EOF | theme_generate "$dest"
# NIRUPI theme — generated from tokens.env; do not edit. Re-run: nirupi theme apply
# Compositor settings; shadow tinted from the active palette. No rounded corners.
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-opacity = 0.45;
shadow-color = "#$NOIR_BG";
shadow-exclude = [ "class_g = 'slock'", "class_g = 'Dunst'", "class_g = 'rofi'" ];
corner-radius = 0;
fading = true;
fade-in-step = 0.06;
fade-out-step = 0.06;
inactive-opacity = 0.96;
active-opacity = 1.0;
inactive-dim = 0.0;
blur-background = false;
detect-client-opacity = true;
unredir-if-possible = true;
focus-exclude = [ "class_g = 'slock'" ];
EOF
}

# SDDM theme colors generated from tokens into a user-writable staging dir that
# the installer copies to /usr/share/sddm/themes/niru-noir (see configure_sddm).
theme_render_sddm(){
  local src; src="$(sddm_dir)/Main.qml"
  local out="$HOME/.local/share/nirupi/sddm" tmp
  [[ -f $src ]] || return 0
  [[ -L $HOME/.local/share/nirupi ]] && { warn 'Preserving symlinked nirupi share dir'; return 0; }
  mkdir -p "$out"
  tmp="$(mktemp "$out/.Main.XXXXXXXX")"
  awk -v bg="$NOIR_BG" -v fg="$NOIR_FG" -v muted="$NOIR_MUTED" -v dim="$NOIR_FOCUS" \
      -v line="$NOIR_BORDER" -v warn="$NOIR_ANSI_1" '
    /BEGIN NIRU-NOIR-COLORS/ {
      print "    // BEGIN NIRU-NOIR-COLORS (generated from tokens.env; do not edit)"
      print "    color: \"#" bg "\""
      print "    property color fg: \"#" fg "\""
      print "    property color muted: \"#" muted "\""
      print "    property color dim: \"#" dim "\""
      print "    property color line: \"#" line "\""
      print "    property color inputBg: \"#" bg "\""
      print "    property color inputBorder: \"#" line "\""
      print "    property color focusBorder: \"#" dim "\""
      print "    property color warn: \"#" warn "\""
      skip=1; next
    }
    /END NIRU-NOIR-COLORS/ { skip=0 }
    skip != 1 { print }
  ' "$src" > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$out/Main.qml"
  # Copy the remaining static theme files (metadata, qmldir, helpers).
  local f rel
  for f in "$(sddm_dir)"/*; do
    rel="$(basename "$f")"
    [[ $rel == Main.qml ]] && continue
    [[ -f $f && ! -L $f ]] || continue
    cp -f -- "$f" "$out/$rel"
  done
  printf 'NIRU Noir SDDM theme staged at %s\n' "$out"
}

# ── Per-app generated colour fragments ───────────────────────────────────────
# Every function below writes a NIRUPI-owned file rendered from the active
# tokens. App configs (bundled, three-way merged) only *include* these, so a
# palette switch updates all of them without touching user edits.

# kitty: ~/.config/nirupi/theme/kitty.conf, included by ~/.config/kitty/kitty.conf
theme_render_kitty(){
  local dest="$(theme_gen_dir)/kitty.conf" i v
  {
    printf '# NIRUPI theme colours — generated from tokens.env; do not edit.\n'
    printf '# Re-run: nirupi theme apply\n'
    printf 'background #%s\nforeground #%s\n' "$NOIR_BG" "$NOIR_FG"
    printf 'cursor #%s\ncursor_text_color #%s\n' "$NOIR_FG" "$NOIR_BG"
    printf 'selection_foreground #%s\nselection_background #%s\n' "$NOIR_FG" "$NOIR_SELECTION"
    printf 'active_border_color #%s\ninactive_border_color #%s\nbell_border_color #%s\n' \
      "$NOIR_FOCUS" "$NOIR_BORDER" "$NOIR_FOCUS"
    printf 'url_color #%s\n' "$NOIR_ANSI_4"
    printf 'active_tab_foreground #%s\nactive_tab_background #%s\n' "$NOIR_BG" "$NOIR_SELECTION"
    printf 'inactive_tab_foreground #%s\ninactive_tab_background #%s\n' "$NOIR_MUTED" "$NOIR_BG"
    printf 'mark1_foreground #%s\nmark1_background #%s\n' "$NOIR_BG" "$NOIR_ANSI_4"
    for i in $(seq 0 15); do
      eval "v=\${NOIR_ANSI_$i}"
      printf 'color%s #%s\n' "$i" "$v"
    done
  } | theme_generate "$dest"
}

# alacritty: imported by ~/.config/alacritty/alacritty.toml ([general] import).
theme_render_alacritty(){
  local dest="$(theme_gen_dir)/alacritty.toml" i v
  local names=(black red green yellow blue magenta cyan white)
  {
    printf '# NIRUPI theme colours — generated from tokens.env; do not edit.\n'
    printf '[colors.primary]\nbackground = "0x%s"\nforeground = "0x%s"\n\n' "$NOIR_BG" "$NOIR_FG"
    printf '[colors.cursor]\ntext = "0x%s"\ncursor = "0x%s"\n\n' "$NOIR_BG" "$NOIR_FG"
    printf '[colors.selection]\ntext = "0x%s"\nbackground = "0x%s"\n\n' "$NOIR_FG" "$NOIR_SELECTION"
    printf '[colors.normal]\n'
    for i in 0 1 2 3 4 5 6 7; do
      eval "v=\${NOIR_ANSI_$i}"
      printf '%s = "0x%s"\n' "${names[$i]}" "$v"
    done
    printf '\n[colors.bright]\n'
    for i in 8 9 10 11 12 13 14 15; do
      eval "v=\${NOIR_ANSI_$i}"
      printf '%s = "0x%s"\n' "${names[$((i - 8))]}" "$v"
    done
  } | theme_generate "$dest"
}

# fish: sourced by ~/.config/fish/config.fish.
theme_render_fish(){
  local dest="$(theme_gen_dir)/fish.fish"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf 'set -g fish_color_normal %s\n' "$NOIR_FG"
    printf 'set -g fish_color_command %s\n' "$NOIR_ANSI_4"
    printf 'set -g fish_color_keyword %s\n' "$NOIR_ANSI_5"
    printf 'set -g fish_color_quote %s\n' "$NOIR_ANSI_2"
    printf 'set -g fish_color_redirection %s\n' "$NOIR_ANSI_3"
    printf 'set -g fish_color_end %s\n' "$NOIR_ANSI_6"
    printf 'set -g fish_color_error %s\n' "$NOIR_ANSI_1"
    printf 'set -g fish_color_param %s\n' "$NOIR_FG"
    printf 'set -g fish_color_comment %s\n' "$NOIR_MUTED"
    printf 'set -g fish_color_operator %s\n' "$NOIR_ANSI_6"
    printf 'set -g fish_color_escape %s\n' "$NOIR_ANSI_5"
    printf 'set -g fish_color_autosuggestion %s\n' "$NOIR_MUTED"
    printf 'set -g fish_color_selection --background=%s\n' "$NOIR_SELECTION"
    printf 'set -g fish_color_search_match --background=%s\n' "$NOIR_SELECTION"
    printf 'set -g fish_color_history_current --bold\n'
    printf 'set -g fish_pager_color_prefix %s\n' "$NOIR_ANSI_4"
    printf 'set -g fish_pager_color_completion %s\n' "$NOIR_FG"
    printf 'set -g fish_pager_color_description %s\n' "$NOIR_MUTED"
    printf 'set -g fish_pager_color_selected_background --background=%s\n' "$NOIR_SELECTION"
  } | theme_generate "$dest"
}

# tmux: sourced (best-effort) from ~/.config/tmux/tmux.conf.
theme_render_tmux(){
  local dest="$(theme_gen_dir)/tmux.conf"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf 'set -g status-style "bg=#%s,fg=#%s"\n' "$NOIR_BG" "$NOIR_MUTED"
    printf 'set -g status-left "#[fg=#%s,bg=#%s,bold] #S #[default] "\n' "$NOIR_BG" "$NOIR_ANSI_4"
    printf 'set -g status-right "#[fg=#%s]%%Y-%%m-%%d #[fg=#%s]%%H:%%M #[default]"\n' "$NOIR_MUTED" "$NOIR_FG"
    printf 'setw -g window-status-current-style "fg=#%s,bg=#%s,bold"\n' "$NOIR_FG" "$NOIR_BORDER"
    printf 'setw -g window-status-style "fg=#%s,bg=#%s"\n' "$NOIR_MUTED" "$NOIR_BG"
    printf 'setw -g pane-border-style "fg=#%s"\n' "$NOIR_BORDER"
    printf 'setw -g pane-active-border-style "fg=#%s"\n' "$NOIR_FOCUS"
    printf 'set -g message-style "bg=#%s,fg=#%s"\n' "$NOIR_SELECTION" "$NOIR_FG"
    printf 'set -g message-command-style "bg=#%s,fg=#%s"\n' "$NOIR_SELECTION" "$NOIR_FG"
    printf 'setw -g mode-style "bg=#%s,fg=#%s"\n' "$NOIR_SELECTION" "$NOIR_FG"
  } | theme_generate "$dest"
}

# lazygit: no include support, so the whole (theme-only) config is generated.
# Routed through the managed-config merge so a user-edited config.yml is
# preserved (with a *.nirupi-new proposal) instead of being silently replaced.
theme_render_lazygit(){
  local dest="$(cfgdir)/lazygit/config.yml" tmp
  [[ -L $(cfgdir)/lazygit ]] && { warn 'Preserving symlinked ~/.config/lazygit'; return 0; }
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$(dirname "$dest")/.nirupi-lazygit.XXXXXXXX")"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf 'gui:\n  theme:\n'
    printf '    activeBorderColor:\n      - '"'"'#%s'"'"'\n      - bold\n' "$NOIR_ANSI_4"
    printf '    inactiveBorderColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_BORDER"
    printf '    optionsTextColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_MUTED"
    printf '    selectedLineBgColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_SELECTION"
    printf '    selectedRangeBgColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_SELECTION"
    printf '    cherryPickedCommitBgColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_ANSI_6"
    printf '    cherryPickedCommitFgColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_BG"
    printf '    unstagedChangesColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_ANSI_1"
    printf '    defaultFgColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_FG"
    printf '    searchingActiveBorderColor:\n      - '"'"'#%s'"'"'\n' "$NOIR_ANSI_3"
    printf '  authorColors:\n    '"'"'*'"'"': '"'"'#%s'"'"'\n' "$NOIR_ANSI_12"
  } > "$tmp"
  chmod 0644 "$tmp"
  managed_config_install 'lazygit/config.yml' "$tmp" "$dest" 0644
  rm -f -- "$tmp"
}

# micro: one generated colorscheme file, selected via settings.json.
theme_render_micro(){
  local dest="$(cfgdir)/micro/colorschemes/nirupi.micro"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf 'color-link default "#%s,#%s"\n' "$NOIR_FG" "$NOIR_BG"
    printf 'color-link comment "#%s,#%s"\n' "$NOIR_MUTED" "$NOIR_BG"
    printf 'color-link constant "#%s,#%s"\n' "$NOIR_ANSI_5" "$NOIR_BG"
    printf 'color-link constant.string "#%s,#%s"\n' "$NOIR_ANSI_2" "$NOIR_BG"
    printf 'color-link constant.number "#%s,#%s"\n' "$NOIR_ANSI_3" "$NOIR_BG"
    printf 'color-link identifier "#%s,#%s"\n' "$NOIR_FG" "$NOIR_BG"
    printf 'color-link statement "#%s,#%s"\n' "$NOIR_ANSI_4" "$NOIR_BG"
    printf 'color-link preproc "#%s,#%s"\n' "$NOIR_ANSI_5" "$NOIR_BG"
    printf 'color-link type "#%s,#%s"\n' "$NOIR_ANSI_6" "$NOIR_BG"
    printf 'color-link special "#%s,#%s"\n' "$NOIR_ANSI_3" "$NOIR_BG"
    printf 'color-link underlined "#%s,#%s"\n' "$NOIR_ANSI_4" "$NOIR_BG"
    printf 'color-link error "#%s,#%s"\n' "$NOIR_ANSI_1" "$NOIR_BG"
    printf 'color-link todo "#%s,#%s"\n' "$NOIR_ANSI_3" "$NOIR_BG"
    printf 'color-link statusline "#%s,#%s"\n' "$NOIR_MUTED" "$NOIR_BORDER"
    printf 'color-link tabbar "#%s,#%s"\n' "$NOIR_MUTED" "$NOIR_BORDER"
    printf 'color-link indent-char "#%s,#%s"\n' "$NOIR_BORDER" "$NOIR_BG"
    printf 'color-link line-number "#%s,#%s"\n' "$NOIR_MUTED" "$NOIR_BG"
    printf 'color-link current-line-number "#%s,#%s"\n' "$NOIR_FG" "$NOIR_BG"
    printf 'color-link cursor-line ",#%s"\n' "$NOIR_BORDER"
    printf 'color-link color-column ",#%s"\n' "$NOIR_BORDER"
    printf 'color-link match-brace "#%s,#%s"\n' "$NOIR_BG" "$NOIR_ANSI_3"
    printf 'color-link selection "#%s,#%s"\n' "$NOIR_FG" "$NOIR_SELECTION"
    printf 'color-link tab-error "#%s"\n' "$NOIR_ANSI_1"
  } | theme_generate "$dest"
}

# aerc: the styleset file is loaded by name (styleset-name = nirupi).
theme_render_aerc(){
  local dest="$(cfgdir)/aerc/stylesets/nirupi"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf '*.default = fg #%s bg #%s\n' "$NOIR_FG" "$NOIR_BG"
    printf '*.unread = fg #%s bg #%s bold\n' "$NOIR_FG" "$NOIR_BG"
    printf '*.marked = fg #%s bg #%s\n' "$NOIR_BG" "$NOIR_ANSI_4"
    printf '*.deleted = fg #%s bg #%s\n' "$NOIR_ANSI_1" "$NOIR_BG"
    printf '*.error = fg #%s bg #%s bold\n' "$NOIR_ANSI_1" "$NOIR_BG"
    printf '*.completed = fg #%s bg #%s\n' "$NOIR_MUTED" "$NOIR_BG"
    printf '*.statusline_default = fg #%s bg #%s\n' "$NOIR_MUTED" "$NOIR_BG"
    printf '*.statusline_error = fg #%s bg #%s\n' "$NOIR_BG" "$NOIR_ANSI_1"
    printf '*.statusline_success = fg #%s bg #%s\n' "$NOIR_BG" "$NOIR_ANSI_2"
    printf '*.border = fg #%s bg #%s\n' "$NOIR_BORDER" "$NOIR_BG"
    printf '*.border_center = fg #%s bg #%s\n' "$NOIR_BORDER" "$NOIR_BG"
    printf '*.border_char = fg #%s bg #%s\n' "$NOIR_FOCUS" "$NOIR_BG"
    printf '*.title = fg #%s bg #%s bold\n' "$NOIR_ANSI_4" "$NOIR_BG"
    printf '*.msglist_unread = fg #%s bg #%s bold\n' "$NOIR_FG" "$NOIR_BG"
    printf '*.msglist_read = fg #%s bg #%s\n' "$NOIR_MUTED" "$NOIR_BG"
    printf '*.msglist_deleted = fg #%s bg #%s\n' "$NOIR_ANSI_1" "$NOIR_BG"
    printf '*.msglist_marked = fg #%s bg #%s\n' "$NOIR_BG" "$NOIR_ANSI_4"
    printf '*.msglist_result = fg #%s bg #%s\n' "$NOIR_FG" "$NOIR_SELECTION"
  } | theme_generate "$dest"
}

# cmus: cmus colours are 256-colour indices, so map the hex tokens. The theme
# file is loaded by name; ensure the rc selects it (only when absent).
theme_render_cmus(){
  local dest="$(cfgdir)/cmus/nirupi.theme"
  {
    printf '# NIRUPI theme — generated from tokens.env; do not edit.\n'
    printf 'set color_cmdline_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_cmdline_bg=default\n'
    printf 'set color_separator=%s\n' "$(_hex_to_xterm "$NOIR_BORDER")"
    printf 'set color_statusline_bg=default\n'
    printf 'set color_statusline_fg=%s\n' "$(_hex_to_xterm "$NOIR_MUTED")"
    printf 'set color_titleline_bg=default\n'
    printf 'set color_titleline_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_bg=default\n'
    printf 'set color_win_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_cur=%s\n' "$(_hex_to_xterm "$NOIR_ANSI_11")"
    printf 'set color_win_dir=%s\n' "$(_hex_to_xterm "$NOIR_ANSI_4")"
    printf 'set color_win_inactive_cur_sel_bg=%s\n' "$(_hex_to_xterm "$NOIR_SELECTION")"
    printf 'set color_win_inactive_cur_sel_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_inactive_sel_bg=%s\n' "$(_hex_to_xterm "$NOIR_SELECTION")"
    printf 'set color_win_inactive_sel_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_cur_sel_bg=%s\n' "$(_hex_to_xterm "$NOIR_SELECTION")"
    printf 'set color_win_cur_sel_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_sel_bg=%s\n' "$(_hex_to_xterm "$NOIR_SELECTION")"
    printf 'set color_win_sel_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_win_title_bg=%s\n' "$(_hex_to_xterm "$NOIR_SELECTION")"
    printf 'set color_win_title_fg=%s\n' "$(_hex_to_xterm "$NOIR_FG")"
    printf 'set color_error=%s\n' "$(_hex_to_xterm "$NOIR_ANSI_1")"
    printf 'set color_info=%s\n' "$(_hex_to_xterm "$NOIR_ANSI_3")"
  } | theme_generate "$dest"
  local rc="$(cfgdir)/cmus/rc"
  if [[ ! -e $rc && ! -L $rc ]]; then
    printf 'colorscheme nirupi\n' | theme_generate "$rc"
  elif [[ -f $rc && ! -L $rc ]] && ! grep -q '^colorscheme ' "$rc"; then
    printf 'colorscheme nirupi\n' >> "$rc"
  fi
}

# Status-bar accent colours consumed by dwm-status.sh (only shown when colour is
# enabled — wallpaper mode or BAR_COLOR=1).
theme_render_statusbar(){
  local dest="$(theme_gen_dir)/status.env"
  {
    printf '# NIRUPI status-bar accents — generated; do not edit.\n'
    printf 'NIRUPI_C_RED=%s\n' "$NOIR_ANSI_1"
    printf 'NIRUPI_C_MUTED=%s\n' "$NOIR_MUTED"
    printf 'NIRUPI_C_YELLOW=%s\n' "$NOIR_ANSI_3"
    printf 'NIRUPI_C_BLUE=%s\n' "$NOIR_ANSI_4"
    printf 'NIRUPI_C_CYAN=%s\n' "$NOIR_ANSI_6"
  } | theme_generate "$dest"
}

# ── Built-in themes (curated token variants) ─────────────────────────────────
theme_palette_dir(){ printf '%s/theme' "$(noir_dir)"; }

# Resolve a theme name (file stem, alias, or display name) to a palette file.
# Accepts the stems (Satie, Carl-Larsson), the display names the picker shows
# (Noir, Noir warm, Carl Larsson) and the aliases (default, warm, cool).
# Matching is case-insensitive and treats spaces and hyphens as equivalent.
theme_palette_file(){
  local n="${1:-noir}" d f base dn key bk dk; d="$(theme_palette_dir)"
  case "${n,,}" in
    ''|noir|default) printf '%s/tokens.env' "$d"; return 0;;
    warm)  printf '%s/Noir-warm.env' "$d"; return 0;;
    cool)  printf '%s/Noir-cool.env' "$d"; return 0;;
    carl|larsson) [[ -f $d/Carl-Larsson.env ]] && { printf '%s' "$d/Carl-Larsson.env"; return 0; };;
  esac
  [[ -f "$d/$n.env" ]] && { printf '%s/%s.env' "$d" "$n"; return 0; }
  key="${n,,}"; key="${key// /-}"
  for f in "$d"/*.env; do
    [[ -e $f ]] || continue
    base="$(basename "$f" .env)"; bk="${base,,}"; bk="${bk// /-}"
    [[ $bk == "$key" ]] && { printf '%s' "$f"; return 0; }
    dn="$(palette_name "$f")"; dk="${dn,,}"; dk="${dk// /-}"
    [[ -n $dn && $dk == "$key" ]] && { printf '%s' "$f"; return 0; }
  done
  return 1
}

# The theme currently in effect (user override, else the bundled default).
theme_current(){
  local tf="$(cfgdir)/nirupi/tokens.env" nm="" bg f
  if [[ -f $tf && ! -L $tf ]]; then nm="$(palette_name "$tf")"; fi
  if [[ -z $nm && -f $tf && ! -L $tf ]]; then
    # Pre-0.8 palette files carry no NOIR_THEME_NAME: identify by background.
    bg="$(palette_field "$tf" NOIR_BG)"
    if [[ -n $bg ]]; then
      for f in "$(theme_palette_dir)"/*.env; do
        [[ -e $f ]] || continue
        [[ "$(palette_field "$f" NOIR_BG)" == "$bg" ]] || continue
        nm="$(palette_name "$f")"; [[ -n $nm ]] && break
      done
    fi
  fi
  if [[ -z $nm ]]; then nm="$(palette_name "$(theme_palette_dir)/tokens.env")"; fi
  printf '%s' "${nm:-noir}"
}

# Ordered list of selectable theme file stems.
theme_names(){
  local d n f; d="$(theme_palette_dir)"
  [[ -f $d/tokens.env ]] && printf 'noir\n'
  for f in "$d"/*.env; do
    [[ -e $f ]] || continue
    n="$(basename "$f" .env)"
    [[ $n == tokens ]] && continue
    printf '%s\n' "$n"
  done
}

# A row of Pango colour swatches for one palette (used by the picker).
palette_swatch(){
  local f="$1" out=""
  [[ -f $f && ! -L $f ]] || return 0
  (
    set +u
    # shellcheck disable=SC1090
    source "$f" >/dev/null 2>&1 || true
    local c
    for c in "$NOIR_BG" "$NOIR_ANSI_1" "$NOIR_ANSI_2" "$NOIR_ANSI_3" "$NOIR_ANSI_4" "$NOIR_ANSI_6" "$NOIR_FG"; do
      [[ -n $c ]] && out+="<span background=\"#${c}\">   </span>"
    done
    printf '%s' "$out"
  )
}

theme_list(){
  local d n f nm desc active; d="$(theme_palette_dir)"
  active="$(theme_current)"
  printf 'Available themes (active: %s):\n' "$active"
  while IFS= read -r n; do
    [[ -n $n ]] || continue
    f="$(theme_palette_file "$n")" || continue
    nm="$(palette_name "$f")"; [[ -n $nm ]] || nm="$n"
    desc="$(palette_field "$f" NOIR_THEME_DESC)"
    [[ $nm == "$active" ]] && nm="$nm (active)"
    if [[ -n $desc ]]; then printf '  %-14s %s — %s\n' "$n" "$nm" "$desc"
    else printf '  %-14s %s\n' "$n" "$nm"; fi
  done < <(theme_names)
  printf '\nApply with: nirupi theme set NAME   (or pick: nirupi theme menu)\n'
}

# Human-readable preview: name, swatches, palette and metadata.
theme_preview(){
  local n="${1:-}" f nm; [[ -n $n ]] || die 'Usage: nirupi theme preview NAME (see nirupi theme list)'
  f="$(theme_palette_file "$n")" || die "Unknown theme: $n"
  nm="$(palette_name "$f")"; [[ -n $nm ]] || nm="$n"
  printf 'Theme: %s (%s)\n' "$nm" "$f"
  printf 'Swatches: %s\n' "$(palette_swatch "$f")"
  grep -E '^NOIR_(BG|FG|MUTED|SELECTION|BORDER|FOCUS|ANSI_[0-9]+)=' "$f"
}

# Interactive picker: rofi with colour swatches + description (dmenu/plain fallback).
theme_menu(){
  local n f nm desc rows="" sel name active mark
  active="$(theme_current)"
  while IFS= read -r n; do
    [[ -n $n ]] || continue
    f="$(theme_palette_file "$n")" || continue
    [[ -f $f ]] || continue
    nm="$(palette_name "$f")"; [[ -n $nm ]] || nm="$n"
    desc="$(palette_field "$f" NOIR_THEME_DESC)"
    mark=""; [[ $nm == "$active" ]] && mark="  ✓"
    if command -v rofi >/dev/null 2>&1; then
      # The swatch markup comes first, so the selected name is everything
      # before the first '<' (see the sed below).
      rows+="$nm"$'\t'"$(palette_swatch "$f")"$'  '"$desc$mark"$'\n'
    else
      [[ -n $mark ]] && nm="$nm (active)"
      rows+="$nm"$'\n'
    fi
  done < <(theme_names)
  [[ -n $rows ]] || die 'No themes found'
  if command -v rofi >/dev/null 2>&1; then
    sel="$(printf '%s' "$rows" | rofi -dmenu -i -markup-rows -p 'Theme' \
      -mesg 'Pick a theme — applies everywhere, live')" || return 0
    name="$(printf '%s' "$sel" | sed 's/<.*//; s/[[:space:]]*$//')"
  elif command -v dmenu >/dev/null 2>&1; then
    sel="$(printf '%s' "$rows" | dmenu -i -p 'Theme')" || return 0
    name="$sel"
  else
    printf '%s' "$rows"; return 0
  fi
  [[ -n $name ]] || return 0
  theme_set "$name"
}

# Apply a built-in (or custom) theme as the active user tokens.env.
theme_set(){
  local n="${1:-}" f nm
  [[ -n $n ]] || die 'Usage: nirupi theme set NAME'
  f="$(theme_palette_file "$n")" || die "Unknown theme: $n (see nirupi theme list)"
  [[ -n $f && -f $f ]] || die "Unknown theme: $n (see nirupi theme list)"
  nm="$(palette_name "$f")"; [[ -n $nm ]] || nm="$n"
  mkdir -p "$(dirname "$(theme_mode_file)")"
  if [[ $f == "$(theme_palette_dir)/tokens.env" ]]; then
    # The bundled default: keep no user override (same as `theme mode noir`).
    rm -f -- "$(cfgdir)/nirupi/tokens.env"
    printf 'noir\n' > "$(theme_mode_file)"
  else
    mkdir -p "$(cfgdir)/nirupi"
    [[ ! -L "$(cfgdir)/nirupi/tokens.env" ]] || die "Refusing symlinked $(cfgdir)/nirupi/tokens.env"
    cp -f -- "$f" "$(cfgdir)/nirupi/tokens.env"
    printf 'palette\n' > "$(theme_mode_file)"
  fi
  log "Theme set to $nm"
  theme_apply
  # Best-effort feedback so a live switch is obvious. Suppressed in tests and
  # other non-interactive use via NIRUPI_NO_NOTIFY=1.
  if [[ -z ${NIRUPI_NO_NOTIFY:-} && -n ${DISPLAY:-} ]] && command -v notify-send >/dev/null 2>&1; then
    notify-send -a NIRUPI "NIRU theme" "$nm" >/dev/null 2>&1 || :
  fi
}

# Full theme application. $1 = optional noir directory.
theme_apply(){
  local noir; noir="${1:-$(noir_dir)}"
  [[ -d $noir/config ]] || die "Missing Noir config bundle: $noir/config"
  theme_load_tokens
  log "Applying NIRU Noir theme (bg=#$NOIR_BG, font=$NOIR_FONT)"
  theme_apply_configs "$noir"
  theme_apply_browser_flags "$noir"
  theme_apply_environment
  theme_apply_gtk4
  theme_install_fonts
  theme_render_rofi
  theme_render_dunst
  theme_render_picom
  theme_render_sddm
  theme_render_kitty
  theme_render_alacritty
  theme_render_fish
  theme_render_tmux
  theme_render_lazygit
  theme_render_micro
  theme_render_aerc
  theme_render_cmus
  theme_render_statusbar
  theme_write_xresources
  if [[ -n ${DISPLAY:-} ]] && command -v xrdb >/dev/null 2>&1; then
    xrdb -merge "$(cfgdir)/nirupi/xresources.noir" 2>/dev/null || :
    command -v xdotool >/dev/null 2>&1 && xdotool key --clearmodifiers super+shift+r >/dev/null 2>&1 || :
    theme_reload_running
  fi
  if [[ -x $HOME/.local/bin/nirupi-appearance ]]; then
    "$HOME/.local/bin/nirupi-appearance" apply noir >/dev/null 2>&1 || \
      warn 'GTK appearance helper unavailable; use nirupi appearance status'
  fi
  log "Theme applied (${NOIR_THEME_NAME:-noir}: bg=#$NOIR_BG)"
}

# Best-effort live reload of running apps after a palette switch. Never fatal:
# st and kitty reload on SIGUSR1, dunst and tmux are told to re-read their config.
theme_reload_running(){
  pgrep -x st >/dev/null 2>&1 && pkill -USR1 -x st 2>/dev/null || :
  pgrep -x kitty >/dev/null 2>&1 && pkill -USR1 -x kitty 2>/dev/null || :
  if command -v dunstctl >/dev/null 2>&1 && pgrep -x dunst >/dev/null 2>&1; then
    dunstctl reload >/dev/null 2>&1 || :
  fi
  if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
    tmux source-file "$(theme_gen_dir)/tmux.conf" >/dev/null 2>&1 || :
  fi
  command -v xsetroot >/dev/null 2>&1 && xsetroot -solid "#$NOIR_BG" 2>/dev/null || :
}

theme_status(){
  theme_load_tokens
  printf 'NIRU theme: %s\n' "${NOIR_THEME_NAME:-noir}"
  printf '  background: #%s\n' "$NOIR_BG"
  printf '  foreground: #%s\n' "$NOIR_FG"
  printf '  font: %s %s\n' "$NOIR_FONT" "$NOIR_FONT_SIZE"
  printf '  tokens from: %s\n' "$(theme_tokens_file)"
  local app
  for app in "${NIRUPI_THEME_APPS[@]}"; do
    [[ -d $(cfgdir)/$app ]] || continue
    printf '  config: ~/.config/%s\n' "$app"
  done
}

theme_diff(){
  theme_load_tokens
  local app src dest rel
  local noir; noir="$(noir_dir)"
  printf 'NIRU Noir theme diff (bundle vs installed)\n'
  for app in "${NIRUPI_THEME_APPS[@]}"; do
    [[ -d $noir/config/$app ]] || continue
    while IFS= read -r -d '' src; do
      [[ $(basename "$src") == fish_variables ]] && continue
      rel="${src#"$noir/config/$app/"}"
      dest="$(cfgdir)/$app/$rel"
      if [[ ! -e $dest ]]; then
        printf '  NEW      ~/.config/%s/%s\n' "$app" "$rel"
      elif cmp -s -- "$src" "$dest"; then
        printf '  CURRENT  ~/.config/%s/%s\n' "$app" "$rel"
      else
        printf '  CHANGED  ~/.config/%s/%s\n' "$app" "$rel"
      fi
    done < <(find "$noir/config/$app" -type f -print0)
  done
}

# ── Dynamic (wallpaper) theming — opt-in, driven by ImageMagick ───────────────
_hex_parts(){ local h="${1#\#}"; printf '%d %d %d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"; }
_hex_lum(){ local r g b; read -r r g b < <(_hex_parts "$1"); printf '%d' "$(( (r*299 + g*587 + b*114) / 1000 ))"; }
_hex_mix(){ # mix a toward b by pct (0-100)
  local r1 g1 b1 r2 g2 b2
  read -r r1 g1 b1 < <(_hex_parts "$1"); read -r r2 g2 b2 < <(_hex_parts "$2")
  printf '%02x%02x%02x' $(( (r1*(100-$3) + r2*$3)/100 )) $(( (g1*(100-$3) + g2*$3)/100 )) $(( (b1*(100-$3) + b2*$3)/100 ))
}
_hex_to_xterm(){ # nearest xterm-256 index for a hex colour (no '#')
  local r g b
  read -r r g b < <(_hex_parts "$1")
  # grayscale ramp when the channels are close, otherwise the 6x6x6 cube.
  local mx=$r mn=$r
  (( g > mx )) && mx=$g; (( g < mn )) && mn=$g
  (( b > mx )) && mx=$b; (( b < mn )) && mn=$b
  if (( mx - mn < 16 )); then
    if (( mx < 8 )); then printf '0'; return; fi
    if (( mx > 248 )); then printf '231'; return; fi
    printf '%d' $(( 232 + (mx - 8) * 24 / 247 ))
    return
  fi
  local ri=$(( (r * 5 + 127) / 255 )) gi=$(( (g * 5 + 127) / 255 )) bi=$(( (b * 5 + 127) / 255 ))
  printf '%d' $(( 16 + 36 * ri + 6 * gi + bi ))
}

theme_mode_file(){ printf '%s/nirupi/theme.mode' "$(cfgdir)"; }

theme_write_xresources(){
  local noir; noir="$(noir_dir)"
  local dest="$(cfgdir)/nirupi/xresources.noir" tmp
  mkdir -p "$(dirname "$dest")"
  tmp="$(mktemp "$(dirname "$dest")/.xres.XXXXXXXX")"
  {
    printf '! Generated by NIRUPI — NIRU Noir. Do not edit; regenerated by nirupi theme apply.\n'
    printf '*.background: #%s\n*.foreground: #%s\n' "$NOIR_BG" "$NOIR_FG"
    printf '*.cursorColor: #%s\n' "$NOIR_FG"
    local i
    for i in $(seq 0 15); do
      local v; eval "v=\${NOIR_ANSI_$i}"
      printf '*.color%s: #%s\n' "$i" "$v"
      printf 'st.color%s: #%s\n' "$i" "$v"
    done
    printf 'st.background: #%s\nst.foreground: #%s\n' "$NOIR_BG" "$NOIR_FG"
    printf 'st.cursorColor: #%s\nst.cursorColorReverse: #%s\n' "$NOIR_FG" "$NOIR_BG"
    printf 'st.font: %s:pixelsize=12:antialias=true:autohint=true\n' "$NOIR_FONT"
    printf 'dmenu.background: #%s\ndmenu.foreground: #%s\n' "$NOIR_BG" "$NOIR_FG"
    printf 'dmenu.selforeground: #%s\ndmenu.selbackground: #%s\n' "$NOIR_FG" "$NOIR_SELECTION"
    # Runtime dwm colors (xresources patch): Super+Shift+r reloads them live.
    printf 'dwm.foreground: #%s\ndwm.background: #%s\ndwm.border: #%s\n' "$NOIR_FG" "$NOIR_BG" "$NOIR_BORDER"
    printf 'dwm.foregroundSel: #%s\ndwm.backgroundSel: #%s\ndwm.borderSel: #%s\n' "$NOIR_FG" "$NOIR_SELECTION" "$NOIR_FOCUS"
    printf 'dwm.font: %s:%s\n' "$NOIR_FONT" "${NOIR_FONT_SIZE:-11}"
  } > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$dest"
}

theme_from_image(){
  local img="${1:-}"
  if [[ -z $img ]]; then
    local wf="$HOME/.cache/dwm-status/current-wallpaper"
    [[ -r $wf ]] && img="$(cat "$wf" 2>/dev/null || true)"
    [[ -n $img && -f $img ]] || img="$(find "${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | head -n1)"
  fi
  [[ -f $img && ! -L $img ]] || die 'Usage: nirupi theme wallpaper IMAGE'
  local conv; conv="$(command -v magick || command -v convert || true)"
  [[ -n $conv ]] || die 'ImageMagick (magick/convert) is required for wallpaper theming'
  local cols sorted bg fg
  cols="$("$conv" "$img" -resize 64x64 -colors 8 -depth 8 -format %c histogram:info:- 2>/dev/null \
    | grep -oE '#[0-9A-Fa-f]{6}' | tr 'A-F' 'a-f' | awk '!seen[$0]++')"
  [[ -n $cols ]] || die "Could not extract a palette from $img"
  sorted="$(while read -r c; do [[ -n $c ]] && printf '%s %s\n' "$(_hex_lum "$c")" "${c#\#}"; done <<< "$cols" | sort -n | awk '{print $2}')"
  mapfile -t colarr <<< "$sorted"
  bg="${colarr[0]}"
  fg="${colarr[$((${#colarr[@]} - 1))]}"
  # Enforce readable contrast between foreground and background.
  _lbg="$(_hex_lum "$bg")"; _lfg="$(_hex_lum "$fg")"
  _d=$(( _lfg - _lbg )); (( _d < 0 )) && _d=$(( -_d ))
  if (( _d < 110 )); then
    if (( _lbg > 128 )); then fg="0f0f10"; else fg="e5e5e5"; fi
  fi

  local ansi=()
  ansi[0]="$bg"; ansi[7]="$fg"; ansi[8]="$(_hex_mix "$bg" "$fg" 30)"; ansi[15]="$fg"
  local i n=${#colarr[@]}
  for i in 1 2 3 4 5 6; do
    if (( i < n )); then ansi[$i]="${colarr[$i]}"; else ansi[$i]="$(_hex_mix "$bg" "$fg" $((15 + i * 8)))"; fi
    ansi[$((i + 8))]="$(_hex_mix "${ansi[$i]}" "$fg" 45)"
  done

  local dest="$(cfgdir)/nirupi/tokens.env" tmp
  mkdir -p "$(dirname "$dest")"
  [[ ! -L $dest ]] || die "Refusing symlinked tokens.env"
  tmp="$(mktemp "$(dirname "$dest")/.tokens.XXXXXXXX")"
  {
    printf '# Generated by NIRUPI from %s\n' "$img"
    printf 'NOIR_THEME_NAME="Wallpaper"\nNOIR_THEME_DESC="Generated from %s"\n' "$(basename "$img")"
    printf 'NOIR_BG=%s\nNOIR_FG=%s\nNOIR_MUTED=%s\nNOIR_SELECTION=%s\nNOIR_BORDER=%s\nNOIR_FOCUS=%s\n' \
      "$bg" "$fg" "$(_hex_mix "$bg" "$fg" 60)" "$(_hex_mix "$bg" "$fg" 25)" "$(_hex_mix "$bg" "$fg" 15)" "$(_hex_mix "$bg" "$fg" 40)"
    printf 'NOIR_FONT="JetBrainsMono Nerd Font"\nNOIR_FONT_SIZE=11\n'
    for i in $(seq 0 15); do printf 'NOIR_ANSI_%s=%s\n' "$i" "${ansi[$i]}"; done
  } > "$tmp"
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$dest"
  mkdir -p "$(dirname "$(theme_mode_file)")"
  printf 'wallpaper\n' > "$(theme_mode_file)"
  log "Generated palette from $(basename "$img")"
  theme_apply
}

theme_mode(){
  local m="${1:-}" mf; mf="$(theme_mode_file)"
  case "$m" in
    ''|status) [[ -f $mf ]] && cat "$mf" || printf 'noir\n';;
    noir)
      rm -f "$(cfgdir)/nirupi/tokens.env"
      mkdir -p "$(dirname "$mf")"; printf 'noir\n' > "$mf"
      theme_apply;;
    wallpaper)
      [[ -f "$(cfgdir)/nirupi/tokens.env" ]] || die 'No wallpaper palette yet; run: nirupi theme wallpaper IMAGE'
      mkdir -p "$(dirname "$mf")"; printf 'wallpaper\n' > "$mf"
      theme_apply;;
    palette)
      [[ -f "$(cfgdir)/nirupi/tokens.env" ]] || die 'No palette applied yet; run: nirupi theme set NAME'
      mkdir -p "$(dirname "$mf")"; printf 'palette\n' > "$mf"
      theme_apply;;
    *) die 'Usage: nirupi theme mode [noir|wallpaper|palette]';;
  esac
}

nirupi_theme(){
  local sub="${1:-apply}"; shift || :
  case "$sub" in
    apply) theme_apply "${1:-}";;
    status) theme_status;;
    diff) theme_diff;;
    list) theme_list;;
    preview) theme_preview "${1:-}";;
    set|palette) theme_set "${1:-}";;
    menu|pick|choose) theme_menu;;
    wallpaper|from-image) theme_from_image "${1:-}";;
    mode) theme_mode "${1:-}";;
    *) die 'Usage: nirupi theme {apply|status|diff|list|preview NAME|set NAME|menu|wallpaper IMAGE|mode noir|wallpaper|palette}';;
  esac
}
