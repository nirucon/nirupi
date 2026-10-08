# NIRU Noir design system — alpha.18

A minimal matte-graphite desktop with high-contrast text, subdued borders, and semantic terminal colors.

| Token | Value | Use |
|---|---|---|
| Background | `#0f0f10` | DWM, st, Kitty, Alacritty, Dunst |
| Foreground | `#e5e5e5` | Primary text |
| Muted text | `#a8a8a8` | Secondary text |
| Selection | `#3a3a3d` | Active menu row |
| Border | `#2a2a2d` | Inactive window |
| Focus | `#5a5a60` | Active window |
| Error red | `#b87878` | Semantic ANSI red |
| Muted blue | `#819eb5` | Semantic ANSI blue |

## Typography

DWM/dmenu: JetBrainsMono Nerd Font 11; st: 12px; Kitty: 12; Alacritty: 11 (previously 5.5); Dunst: 10. GTK uses Sans 11 as a platform-independent fallback.

The 16 ANSI colors now agree across Kitty, st and Alacritty. Color meaning is preserved (red for errors, green for success, etc.) without bright decoration.

## Unresolved before installation

- JetBrainsMono Nerd Font is **not guaranteed** by current distro package lists; verify or supply a font fallback.
- Rofi and SDDM have related but not identical surface tokens; validate screenshots and runtime behavior.
- Existing customized dotfiles are preserved, so users will not automatically receive theme changes when upgrading.
- Complete source tree still requires GitHub publication and clean-clone verification.
