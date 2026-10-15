# NIRUPI physical test checklist

Run through this on each distribution (Debian, Void glibc, Arch/CachyOS) and
on both a clean install and an in-place upgrade. No automated test can replace
a real login on real hardware.

## Before
- [ ] Local text TTY, logged out of any graphical session, not over SSH.
- [ ] `bash tests/smoke.sh` is green.
- [ ] `bash ./install.sh --plan` reviewed; `--diff` reviewed.
- [ ] Machine backup or snapshot taken.

## Install / upgrade
- [ ] `bash ./install.sh --apply --session sddm|startx` completes.
- [ ] `bash ./install.sh --verify` passes.
- [ ] `nirupi doctor` reports fonts, tools, agent and theme.
- [ ] No keybinding collisions (`bash tests/keybindings.sh`).

## Session
- [ ] Login via SDDM/startx reaches DWM.
- [ ] Status bar is **dark (theme)**, no bright flash at start.
- [ ] Bar segments: media, volume, mic, now-playing, network, Nextcloud (if
      installed), battery, temp, DND, recording, updates, kernel, host,
      weather, date, time.
- [ ] Clicking bar segments works (agent icon, volume scroll, weather, network,
      updates, Nextcloud).
- [ ] `Super+a` opens the agent (opencode); `Super+Shift+h` cheat-sheet;
      `Super+Shift+m` control center; `Super+Alt+k` full keybinding table.
- [ ] `Super+Ctrl+t` opens the theme picker (active theme + description shown);
      choosing **Satie**, **Carl Larsson**, **Hackerman**, **Nord dark** or
      **Noir day** restyles terminals, TUI tools, rofi, dunst and the bar live.
- [ ] `Super+Ctrl+Shift+r` restarts dwm in place (windows survive, no logout).
- [ ] `Super+Ctrl+Print` opens the capture menu; `Super+Ctrl+a` asks the agent
      about the current selection; `Super+Ctrl+s` asks about a screen region.
- [ ] `Super+Ctrl+c` proposes a command you can edit and run on Enter; nothing
      runs without confirmation.
- [ ] `Super+Shift+p` opens the unified launcher (apps / window / clipboard /
      run); `Super+Ctrl+r` rewrites the selected text in place.
- [ ] An autostart entry with `# tag: N` in `~/.config/nirupi/autostart/` opens
      on workspace N at login (`nirupi autostart list` shows it).
- [ ] Low-battery warning appears when discharging below `BATTERY_WARN`.
- [ ] `nirupi notifications` lists history; the clipboard is cleared on lock.
- [ ] picom runs with a palette-tinted shadow and no rounded corners.
- [ ] `Super+Left/Right` (and `Up/Down`) change window focus; with `Shift` they
      move the window in the stack.
- [ ] The launcher's *files* mode finds and opens a file (`Ctrl+Tab` to switch).
- [ ] Control center → *USB: mount/unmount…* mounts a removable drive.
- [ ] `nirupi lid` reports the lid-close behaviour (systemd systems).
- [ ] Clicking each media icon opens Music / Pictures / Videos.
- [ ] `Super+Ctrl+Shift+b` cycles padded → full-bleed → hidden bar.
- [ ] `nirupi calendar`: English UI, Mon..Sun, ISO weeks; `s` sets the iCal URL
      and `o` opens the selected day in Google Calendar.
- [ ] The daily update check pops a notification when updates exist.
- [ ] Battery/weather pop-ups open as centred TUI panels; the calendar looks clean and fits.
- [ ] `Super+Ctrl+Shift+s` keeps a window on all tags; `Super+Ctrl+e` selects the
      fibonacci layout; `Super+Ctrl+arrows` move a floating window.
- [ ] The calendar pop-up fits a small floating window without wrapping.
- [ ] Clicking updates lists pending packages; temp opens btop; battery/disk
      show details; weather shows the forecast.
- [ ] `nirupi changes` prints the changelog; `nirupi fleet` lists the hosts.
- [ ] `nirupi doctor` reports the session and locale.
- [ ] On othala, the two monitors are stacked with the top one upright, and the
      pointer moves up/down between them (also via control center → *Apply
      screen layout*).
- [ ] `Super+s` opens the SSH host picker (add a host to `~/.ssh/config` to see
      one). `nirupi reload` rebuilds+restarts dwm only when needed; `nirupi edit`
      opens a config.
- [ ] Per-workspace wallpapers: switching tags changes the background instantly;
      toggling *Wallpapers per workspace* in the control center turns it off/on.
- [ ] `Super+Shift+r` reloads Xresources colors; `nirupi theme wallpaper IMAGE`
      recolors terminals + bar; `nirupi theme mode noir` restores Noir.
- [ ] Idle for `IDLE_LOCK_MINUTES` (default 10) locks with slock; unlock works.
- [ ] DND toggle (control center) suppresses notifications; indicator shows.

## Apps / tools
- [ ] Terminals st, kitty, alacritty use the active palette and Nerd Font.
- [ ] fish, tmux, lazygit, micro, aerc and dunst use the theme
      (`~/.config/dunst/dunstrc.d/90-nirupi.conf`; your `dunstrc` is untouched).
- [ ] Browser uses `--force-dark-mode` (brave-flags.conf).
- [ ] Screenshots, clipboard, wallpaper rotation, power menu work.
- [ ] Capture menu (`Super+Ctrl+Print`) works; annotation/OCR offered only when
      `satty`/`tesseract` are present.
- [ ] Palette (`Super+Shift+h`) lists Emoji, Transform, Capture, Audio and
      Ask agent, and each launches.
- [ ] `nirupi help theme` and `man nirupi` work; completions load in fish/bash.
- [ ] GTK and Qt apps are dark (no light flash).

## Upgrade-specific
- [ ] Existing DWM config preserved/merged; custom edits kept.
- [ ] Foreign `~/.local/bin/dwm` archived to `~/.local/state/nirupi/legacy/`.
- [ ] `nirupi rollback --all` restores configs and binary links (TTY only).
- [ ] `nirupi backup` writes a tarball (Nextcloud dir if present).
- [ ] `nirupi gc --dry-run` lists only old versions/backups; `--yes` prunes them
      while `dwm`/`dmenu`/`st` links keep working.

## Report
- [ ] Note distribution, kernel, GPU and any segment that misaligns.
- [ ] `Super+g` restores gaps to 15px (twice to undo); a sticky window shows `[S]`.
- [ ] A full screenshot still saves + notifies when `xclip` is missing.
- [ ] `nirupi doctor` hints about missing optional tools.
