# NIRU Noir — design tokens (alpha.18)

## Principles

Minimal, low-noise, matte graphite. High-contrast readable text, subdued borders, restrained color only where it conveys terminal semantics. No bright decorative accents.

## Core colors

| Token | Hex | Purpose |
|---|---|---|
| Background | `#0f0f10` | DWM, Kitty, st, Alacritty, Dunst |
| Foreground | `#e5e5e5` | Primary text |
| Muted text | `#a8a8a8` | Secondary text |
| Selection | `#3a3a3d` | Active menu row |
| Border | `#2a2a2d` | Inactive window |
| Focus border | `#5a5a60` | Focus indication |
| Error red | `#b87878` | ANSI red / error state |
| Muted blue | `#819eb5` | ANSI blue / links |

## Typography

- DWM/dmenu: `JetBrainsMono Nerd Font` 11 pt.
- st: same family, 12 px (existing setting).
- Kitty: same family, 12 pt.
- Alacritty: same family, 11 pt (**previously 5.5**, unreadable).
- Dunst: same family, 10 pt.
- GTK: generic `Sans 11` to avoid platform-specific missing font.

**Font dependency remains a blocker**: JetBrainsMono Nerd Font is not guaranteed by the current distro package lists. Before the first real installation, either package a redistributable licensed font separately, select an installed equivalent with fontconfig, or explicitly install a verified package on each distro. Do not assume the font exists.

## Terminal semantics

The ANSI 16-color palette is now aligned between Kitty, st and Alacritty. Red/green/yellow/blue retain their semantic meaning, rather than mapping red to blue. All colors are desaturated to fit NIRU Noir.

## Not yet unified

Rofi Black-Metal theme and SDDM are visually related but have their own layouts and surface tokens. Their QML/theme runtime and pixel-level consistency require screenshots on real X11/SDDM. Existing user dotfiles are preserved, so upgrades do not forcibly overwrite customized themes.
