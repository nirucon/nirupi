/* DWM config by Nicklas Rudolfsson - https://github.com/nirucon */
/* Vanilla base (dwm 6.8 + status2d/statuscmd/xresources). Requires: brightnessctl, PipeWire, maim, flameshot, rofi, st, alacritty, brave, arandr, playerctl */

/* Config schema marker. dwm.c refuses to build with an older config.h.
 * If you upgrade NIRUPI, merge the new settings (a *.nirupi-new file is
 * written next to your old config) and rebuild: nirupi migrate dwm --rebuild */
#define NIRUPI_CONFIG_VERSION 5

/* ---- Compatibility shim for some patched dwm.c expecting `refreshrate` ---- */
#ifndef REFRESH_RATE
#define REFRESH_RATE 60
#endif
#ifndef refreshrate
#define refreshrate REFRESH_RATE
#endif
/* ---- end shim ---- */

#include <X11/XF86keysym.h> /* hardware keys */

/*========================
  Appearance / Colors
  "MatteBlack" theme
=========================*/
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static unsigned int gappx           = 15;       /* gaps between windows (Super+g toggles) */
static const int smartgaps          = 1;        /* 1 = no gaps when a single tiled window */
static const int smartborders       = 1;        /* 1 = no border on a single tiled window */
static const unsigned int snap      = 32;       /* snap pixel */
static const int swallowfloating    = 0;        /* 1 = terminal also swallows floating windows */
static const int showbar            = 1;        /* 0 hides bar */
static const int topbar             = 1;        /* 0 bottom bar */
static const unsigned int vertpad   = 8;        /* vertical padding of the bar */
static const unsigned int sidepad   = 8;        /* horizontal padding of the bar */

static const char *fonts[]          = {
	"JetBrainsMono Nerd Font:size=11",
	"monospace:size=11"
};
static const char dmenufont[]       = "JetBrainsMono Nerd Font:size=11";

/* MatteBlack palette */
static const char col_bg[]          = "#0f0f10";  /* background */
static const char col_fg[]          = "#e5e5e5";  /* foreground */
static const char col_fg_dim[]      = "#a8a8a8";  /* dim/inactive text */
static const char col_accent[]      = "#3a3a3d";  /* selection bg */
static const char col_border[]      = "#2a2a2d";  /* border (normal) */
static const char col_border_sel[]  = "#5a5a60";  /* border (selected) */

static const char *colors[][3]      = {
	/*               fg         bg           border          */
	[SchemeNorm] = { col_fg_dim, col_bg,      col_border     },
	[SchemeSel]  = { col_fg,     col_accent,  col_border_sel },
};

/*========================
  Tagging / Rules
=========================*/
static const char *tags[] = { "1","2","3","4","5","6","7","8","9" };

/* tagicons: an optional Nerd Font glyph per tag, shown in the bar instead of the
 * numeric label. The numeric tags[] labels remain the source for EWMH desktop
 * names and keybindings (Super+1..9). Empty entries fall back to tags[]. */
static const char *tagicons[] = {
	"\uf0ac",     /* 1 browser / internet (globe) */
	"\U000f06a9", /* 2 AI agent (robot) */
	"\U000f06a9", /* 3 AI agent (robot) */
	"\U000f06a9", /* 4 AI agent (robot) */
	"\uf07b",     /* 5 folder */
	"\uf120",     /* 6 terminal */
	"\uf120",     /* 7 terminal */
	"\uf120",     /* 8 terminal */
	"\uf075",     /* 9 chat */
};

/* Keep rules minimal/vanilla; no app auto-tagging needed for your asks.
 * isterminal marks terminals that may swallow windows they spawn (swallow patch);
 * noswallow opts a window out. Add isfullscreen=1 to launch a rule fullscreen. */
static const Rule rules[] = {
	/* class      instance  title         tags mask  isfloating  isterminal  noswallow  isfullscreen  monitor */
	{ "Gimp",     NULL,     NULL,         0,         1,          0,          0,         0,            -1 },
	{ "kitty",    NULL,     NULL,         0,         0,          1,          0,         0,            -1 },
	{ "Alacritty",NULL,     NULL,         0,         0,          1,          0,         0,            -1 },
	{ "st",       NULL,     NULL,         0,         0,          1,          0,         0,            -1 },
	{ NULL,       NULL,     "scratchpad", 0,         0,          1,          0,         0,            -1 },
	/* Float dialogs/tools that are awkward when tiled. */
	{ "Pavucontrol", NULL,  NULL,         0,         1,          0,          0,         0,            -1 },
	{ "pavucontrol", NULL,  NULL,         0,         1,          0,          0,         0,            -1 },
	{ "Steam",    NULL,     NULL,         0,         1,          0,          0,         0,            -1 },
	{ "steam",    NULL,     NULL,         0,         1,          0,          0,         0,            -1 },
	{ "Lutris",   NULL,     NULL,         0,         1,          0,          0,         0,            -1 },
	{ NULL,       NULL,     "Picture-in-Picture", 0,  1,          0,          0,         0,            -1 },
	{ NULL,       NULL,     "Picture in picture", 0,  1,          0,          0,         0,            -1 },
};

/* === Custom layout funcs === */
#include "tileleft.c"
#include "rstack.c"

/*========================
  Layout(s)
=========================*/
static const float mfact     = 0.55; /* master size factor [0.05..0.95] */
static const int nmaster     = 1;    /* clients in master area */
static const int resizehints = 0;    /* respect size hints */
static const int lockfullscreen = 1; /* focus on fullscreen window */

static const Layout layouts[] = {
    { "[]=",      rstack },                    /* [0] rightstack (master vänster, stack höger) — default */
    { "=[]",      tileleft },                  /* [1] leftstack (stack vänster, master höger) */
    { "><>",      NULL },                      /* [2] floating */
    { "[M]",      monocle },                   /* [3] monocle */
    { "|M|",      centeredmaster },            /* [4] centered master */
    { ">M>",      centeredfloatingmaster },    /* [5] centered floating master */
    { NULL,       NULL },                      /* sentinel: required last for cyclelayouts */
};

/*========================
  Key definitions & helpers
=========================*/
#define MODKEY Mod4Mask  /* Super/Win */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/*========================
  Commands
=========================*/
/* dmenu themed to match MatteBlack */
static char dmenumon[2] = "0";
/* Clickable status sections (statuscmd-nosignal + status2d). The status script
 * prints the section id as a raw byte before and after each clickable segment.
 * The pressed button is exported to the command as $BUTTON. */
static const StatusCmd statuscmds[] = {
	{ "$HOME/.local/bin/nirupi-status-click.sh agent",     1 },
	{ "$HOME/.local/bin/nirupi-status-click.sh menu",      2 },
	{ "$HOME/.local/bin/nirupi-status-click.sh keys",      3 },
	{ "$HOME/.local/bin/nirupi-status-click.sh weather",   4 },
	{ "$HOME/.local/bin/nirupi-status-click.sh updates",   5 },
	{ "$HOME/.local/bin/nirupi-status-click.sh volume",    6 },
	{ "$HOME/.local/bin/nirupi-status-click.sh nextcloud", 7 },
	{ "$HOME/.local/bin/nirupi-status-click.sh network",   8 },
	{ "$HOME/.local/bin/nirupi-status-click.sh battery",   14 },
	{ "$HOME/.local/bin/nirupi-status-click.sh temp",     15 },
	{ "$HOME/.local/bin/nirupi-status-click.sh media",    16 },
	{ "$HOME/.local/bin/nirupi-status-click.sh nowplaying", 17 },
	{ "$HOME/.local/bin/nirupi-status-click.sh mic",      18 },
	{ "$HOME/.local/bin/nirupi-status-click.sh dnd",      19 },
	{ "$HOME/.local/bin/nirupi-status-click.sh recording",20 },
	{ "$HOME/.local/bin/nirupi-status-click.sh memory",   21 },
	{ "$HOME/.local/bin/nirupi-status-click.sh uptime",   22 },
	{ "$HOME/.local/bin/nirupi-status-click.sh disk",     23 },
	{ "$HOME/.local/bin/nirupi-status-click.sh cpu",      24 },
	{ "$HOME/.local/bin/nirupi-status-click.sh load",     25 },
	{ "$HOME/.local/bin/nirupi-status-click.sh bluetooth",26 },
	{ "$HOME/.local/bin/nirupi-status-click.sh kernel",   27 },
	{ "$HOME/.local/bin/nirupi-status-click.sh host",     28 },
	{ "$HOME/.local/bin/nirupi-status-click.sh date",     29 },
	{ "$HOME/.local/bin/nirupi-status-click.sh time",      30 },
	{ "$HOME/.local/bin/nirupi-status-click.sh caffeine",  31 },
};
static const char *statuscmd[] = { "/bin/sh", "-c", NULL, NULL };
static const char *dmenucmd[] = {
	"dmenu_run",
	"-m", dmenumon,
	"-fn", dmenufont,
	"-nb", col_bg, "-nf", col_fg_dim,
	"-sb", col_accent, "-sf", col_fg,
	NULL
};

/* Scratchpad */
static const char scratchpadname[] = "scratchpad";
static const char *scratchpadcmd[] = {
    "kitty",
    "--class", "scratchpad",
    "--title", "scratchpad",
    "--override", "initial_window_width=100c",
    "--override", "initial_window_height=28c",
    NULL
};

/* Launchers / apps */
static const char *stcmd[]        = { "st", NULL };
static const char *alacrittycmd[] = { "alacritty", NULL };
static const char *kittycmd[]     = { "kitty", NULL };
/* Re-spawning DWM from inside DWM is safe: `quit {.i = 1}` releases the WM
 * role (XCloseDisplay) before exec, so Super+Ctrl+Shift+r restarts in place
 * with no competing window manager. */
static const char *browsercmd[] = { "nirupi-browser", NULL };
static const char *bravecmd[]   = { "brave", NULL };
static const char *wallnext[]     = { "/bin/sh", "-c", "$HOME/.local/bin/wallrotate.sh next", NULL };

/* Rofi (Run mode) */
static const char *rofiruncmd[]   = { "rofi", "-show", "run", NULL };

/* Keybindings viewer (TUI) */
static const char *keybindingscmd[] = { 
  "kitty", "--", "sh", "-c", 
  "$HOME/.local/bin/dwm-keybindings.sh -i || dwm-keybindings.sh -i || echo 'Install dwm-keybindings.sh first'; read", 
  NULL 
};

/* Keybinding cheat-sheet / command palette (rofi) */
static const char *keyscmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-keys.sh", NULL };
/* Control center (rofi) */
static const char *menucmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-menu.sh", NULL };
/* AI agent launcher */
static const char *agentcmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-agent.sh", NULL };
/* Ask the agent about the current selection (Super+Ctrl+a). */
static const char *agentselectioncmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-agent-selection.sh", NULL };
/* Ask the agent about a screen region, via OCR (Super+Ctrl+s). */
static const char *askscreencmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-agent-screen.sh", NULL };
/* AI command: describe a task, review the suggested command, run on Enter (Super+Ctrl+c). */
static const char *askcommandcmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-ask-command.sh", NULL };
/* SSH/host picker (Super+s). */
static const char *sshcmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-ssh.sh", NULL };
/* Capture menu: region/window/full + annotate + OCR (Super+Ctrl+Print). */
static const char *capturecmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-capture.sh", NULL };
/* Theme picker (Super+Ctrl+t): rofi with colour swatches, applies live. */
static const char *thememenu[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi theme menu", NULL };

/* Clipboard save */
static const char *clipsavecmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/clip-save.sh", NULL };
static const char *clipmenucmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/clip-menu.sh", NULL };

/* System / security */
static const char *lockcmd[]      = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-lock.sh", NULL }; /* Super+Esc */
static const char *fmcmd[]        = { "pcmanfm", NULL };   /* Super+Shift+f */
/* Power menu (Super+Shift+q): screensaver, lock, suspend/logout/reboot/shutdown
 * (with optional timers). */
static const char *logoutcmd[]    = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-power.sh", NULL };
/* Night light toggle (gammastep/redshift). */
static const char *nightlightcmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-nightlight.sh", NULL };

/* v0.7 feature commands (all minimal, keyboard-first). */
static const char *windowsmenu[]  = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-window.sh", NULL };       /* Super+w band */
static const char *recordcmd[]    = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-record.sh", NULL };        /* Super+r */
static const char *caffeinecmd[]  = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-caffeine.sh", NULL };      /* Super+Shift+c */
static const char *focuscmd[]     = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-focus.sh", NULL };         /* Super+Shift+d */
static const char *kblayoutcmd[]  = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-keyboard.sh", NULL };      /* Super+Shift+k */
static const char *touchpadcmd[]  = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-touchpad.sh", NULL };      /* Super+Shift+t */
static const char *nirunotecmd[]  = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-app.sh nirunote", NULL };  /* Super+Shift+n */
static const char *nplaycmd[]     = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-app.sh nplay", NULL };     /* Super+Shift+o */
static const char *screensavercmd[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-lock.sh -s", NULL };     /* Super+x */

/* Display configuration (F1 screen button) */
static const char *arandrcmd[] = { "arandr", NULL };

/* Brightness (brightnessctl) with a minimal on-screen indicator. */
static const char *br_up[]   = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh brightness up", NULL };
static const char *br_down[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh brightness down", NULL };

/* Audio (PipeWire native) with a minimal on-screen indicator. */
static const char *vol_up[]     = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh volume up", NULL };
static const char *vol_down[]   = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh volume down", NULL };
static const char *vol_toggle[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh volume mute", NULL };
static const char *mic_toggle[] = { "/bin/sh", "-c", "$HOME/.local/bin/nirupi-osd.sh mic mute", NULL };

/* Media control (requires: playerctl) */
static const char *media_play[]     = { "playerctl", "play-pause", NULL };
static const char *media_next[]     = { "playerctl", "next", NULL };
static const char *media_prev[]     = { "playerctl", "previous", NULL };

/* Screenshots (requires: maim, flameshot, slop, xclip, libnotify, rofi, sxiv) */
static const char *ss_select[] = {
  "sh", "-c",
  "$HOME/.local/bin/screenshot-select.sh",
  NULL
};

static const char *ss_browser[] = {
  "sh", "-c",
  "$HOME/.local/bin/screenshot-browser.sh",
  NULL
};

static const char *ss_full[] = {
  "sh", "-c",
  "dir=\"$HOME/Pictures/Screenshots\"; mkdir -p \"$dir\"; "
  "file=\"$dir/$(date +%F_%H-%M-%S).png\"; "
  "maim -u \"$file\" && xclip -selection clipboard -t image/png -i \"$file\" && "
  "notify-send 'Screenshot' \"Saved & copied: $file\"",
  NULL
};

static const char *ss_flameshot[] = {
  "sh", "-c",
  "dir=\"$HOME/Pictures/Screenshots\"; mkdir -p \"$dir\"; "
  "flameshot gui -c -p \"$dir\" && notify-send 'Screenshot' 'Flameshot copied to clipboard'",
  NULL
};

/*========================
  Keys
=========================*/
static const Key keys[] = {
	/* modifier                     key                       function        argument */

	/* Launchers */
	{ MODKEY,                       XK_Return,                spawn,          {.v = kittycmd } },          /* Super+Enter -> kitty */
	{ MODKEY|ShiftMask,             XK_Return,                spawn,          {.v = alacrittycmd } },   /* Super+Shift+Enter -> alacritty */
	{ MODKEY,                       XK_b,                     spawn,          {.v = browsercmd } },       /* Super+b -> Default browser */
	{ MODKEY|ShiftMask,   		XK_b, 			  spawn, 	  {.v = bravecmd } },
	{ MODKEY|ShiftMask,             XK_p,                     spawn,          {.v = rofiruncmd } },     /* Super+Shift+p -> rofi -show run */
	{ MODKEY,                       XK_p,                     spawn,          {.v = dmenucmd } },       /* Super+p -> dmenu (MatteBlack) */
	{ MODKEY|Mod1Mask,              XK_k,                     spawn,          {.v = keybindingscmd } }, /* Super+Alt+k -> keybindings viewer */
	{ MODKEY|ShiftMask,             XK_h,                     spawn,          {.v = keyscmd } },         /* Super+Shift+h -> keybinding palette */
	{ MODKEY|ShiftMask,             XK_m,                     spawn,          {.v = menucmd } },         /* Super+Shift+m -> control center */
	{ MODKEY,                       XK_slash,                 spawn,          {.v = keyscmd } },         /* Super+/ (US layouts) */
	{ MODKEY,                       XK_grave,                 spawn,          {.v = menucmd } },         /* Super+` (US layouts) */
	{ MODKEY,                       XK_a,                     spawn,          {.v = agentcmd } },        /* Super+a -> AI agent (opencode) */
	{ MODKEY|ControlMask,           XK_a,                     spawn,          {.v = agentselectioncmd } }, /* Super+Ctrl+a -> ask agent about selection */
	{ MODKEY|ControlMask,           XK_s,                     spawn,          {.v = askscreencmd } },  /* Super+Ctrl+s -> ask agent about screen (OCR) */
	{ MODKEY|ControlMask,           XK_c,                     spawn,          {.v = askcommandcmd } },  /* Super+Ctrl+c -> AI command (confirm & run) */
	{ MODKEY,                       XK_s,                     spawn,          {.v = sshcmd } },         /* Super+s -> SSH host picker */
	{ MODKEY|ControlMask,           XK_t,                     spawn,          {.v = thememenu } },       /* Super+Ctrl+t -> theme picker */
	{ MODKEY|ShiftMask,             XK_f,                     spawn,          {.v = fmcmd } },          /* Super+Shift+f -> pcmanfm */

	/* Clipboard */
	{ MODKEY,                       XK_v,                     spawn,          {.v = clipmenucmd } },    /* Super+v -> clipboard menu */
	{ MODKEY|ShiftMask,             XK_v,                     spawn,          {.v = clipsavecmd } },    /* Super+Shift+v -> save to clipboard history */

	/* System / security */
	{ MODKEY,                       XK_Escape,                spawn,          {.v = lockcmd } },             /* Super+Esc -> slock */
	{ MODKEY|ShiftMask,             XK_Escape,                spawn,          SHCMD("$HOME/.local/bin/sleep-suspend.sh") },  /* Super+Shift+Esc -> suspend */

	/* Window / layout control */
	{ MODKEY,                       XK_j,                     focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,                     focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,                     incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,                     incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,                     setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,                     setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Tab,                   view,           {0} },
	{ MODKEY,                       XK_space,                 setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,                 togglefloating, {0} },
	{ MODKEY|ShiftMask,             XK_j,                     rotatestack,    {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,                     rotatestack,    {.i = -1 } },

	/* Layout selection */
	{ MODKEY,                       XK_t,                     setlayout,      {.v = &layouts[0]} },    /* Super+t -> right stack */
	{ MODKEY,                       XK_y,                     setlayout,      {.v = &layouts[1]} },    /* Super+y -> left stack */
	{ MODKEY,                       XK_f,                     setlayout,      {.v = &layouts[2]} },    /* Super+f -> floating */
	{ MODKEY,                       XK_m,                     setlayout,      {.v = &layouts[3]} },    /* Super+m -> monocle */
	{ MODKEY,                       XK_c,                     setlayout,      {.v = &layouts[4]} },    /* Super+c -> centered master */
	{ MODKEY,                       XK_u,                     setlayout,      {.v = &layouts[5]} },    /* Super+u -> centered floating master */
	{ MODKEY|ControlMask,           XK_comma,                 cyclelayout,    {.i = -1 } },            /* Super+Ctrl+, -> previous layout */
	{ MODKEY|ControlMask,           XK_period,                cyclelayout,    {.i = +1 } },            /* Super+Ctrl+. -> next layout */

	/* Fullscreen / urgent */
	{ MODKEY|ShiftMask,             XK_e,                     togglefullscr,  {0} },                   /* Super+Shift+e -> actual fullscreen */
	{ MODKEY|ShiftMask,             XK_u,                     focusurgent,    {0} },                   /* Super+Shift+u -> jump to urgent */

	/* Monitors */
	{ MODKEY,                       XK_comma,                 focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period,                focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,                 tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,                tagmon,         {.i = +1 } },

	/* Tags */
	TAGKEYS(                        XK_1,                                     0)
	TAGKEYS(                        XK_2,                                     1)
	TAGKEYS(                        XK_3,                                     2)
	TAGKEYS(                        XK_4,                                     3)
	TAGKEYS(                        XK_5,                                     4)
	TAGKEYS(                        XK_6,                                     5)
	TAGKEYS(                        XK_7,                                     6)
	TAGKEYS(                        XK_8,                                     7)
	TAGKEYS(                        XK_9,                                     8)
	{ MODKEY,                       XK_0,                     view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,                     tag,            {.ui = ~0 } },

	/* Bar toggle */
	{ MODKEY|ControlMask, 		XK_b, 			  togglebar,      {0} },

	/* Kill active window & restart dwm */
	{ MODKEY,                       XK_q,                     killclient,     {0} },          /* Super+q -> kill focused */
	{ MODKEY|ShiftMask,             XK_q,                     spawn,          {.v = logoutcmd } },  /* Super+Shift+q -> power menu */
	{ MODKEY|ControlMask|ShiftMask, XK_q,                     quit,           {0} },          /* Super+Ctrl+Shift+q -> quit immediately */
	{ MODKEY|ControlMask|ShiftMask, XK_r,                     quit,           {.i = 1} },     /* Super+Ctrl+Shift+r -> restart dwm in place */

	/* Night light */
	{ MODKEY,                       XK_n,                     spawn,          {.v = nightlightcmd } }, /* Super+n -> night light toggle */

	/* v0.7 features (all letters: safe on the Swedish layout) */
	{ MODKEY,                       XK_w,                     spawn,          {.v = windowsmenu } },   /* Super+w -> window switcher (rofi) */
	{ MODKEY,                       XK_r,                     spawn,          {.v = recordcmd } },     /* Super+r -> toggle screen recording */
	{ MODKEY,                       XK_g,                     togglegaps,     {0} },                   /* Super+g -> toggle gaps */
	{ MODKEY|ShiftMask,             XK_c,                     spawn,          {.v = caffeinecmd } },   /* Super+Shift+c -> keep awake (caffeine) */
	{ MODKEY|ShiftMask,             XK_d,                     spawn,          {.v = focuscmd } },      /* Super+Shift+d -> focus / do-not-disturb */
	{ MODKEY|ShiftMask,             XK_l,                     spawn,          {.v = kblayoutcmd } },   /* Super+Shift+l -> toggle keyboard layout */
	{ MODKEY|ShiftMask,             XK_t,                     spawn,          {.v = touchpadcmd } },   /* Super+Shift+t -> toggle touchpad */
	{ MODKEY|ShiftMask,             XK_n,                     spawn,          {.v = nirunotecmd } },   /* Super+Shift+n -> nirunote */
	{ MODKEY|ShiftMask,             XK_o,                     spawn,          {.v = nplaycmd } },      /* Super+Shift+o -> nplay */
	{ MODKEY|ShiftMask,             XK_r,                     xresreload,     {0} },                   /* Super+Shift+r -> reload theme colours */
	{ MODKEY,                       XK_x,                     spawn,          {.v = screensavercmd } }, /* Super+x -> screensaver (locks on input) */

	/* Zoom (vanilla) */
	{ MODKEY|ShiftMask,             XK_z,                     zoom,           {0} },

	/* Scratchpad */
	{ MODKEY|ShiftMask,             XK_s,                     togglescratch,  {.v = scratchpadcmd } },

	/* Hardware keys - Brightness */
	{ 0,                            XF86XK_MonBrightnessUp,   spawn,          {.v = br_up } },
	{ 0,                            XF86XK_MonBrightnessDown, spawn,          {.v = br_down } },

	/* Hardware keys - Audio */
	{ 0,                            XF86XK_AudioRaiseVolume,  spawn,          {.v = vol_up } },
	{ 0,                            XF86XK_AudioLowerVolume,  spawn,          {.v = vol_down } },
	{ 0,                            XF86XK_AudioMute,         spawn,          {.v = vol_toggle } },
	{ 0,                            XF86XK_AudioMicMute,      spawn,          {.v = mic_toggle } },

	/* Hardware keys - Media control */
	{ 0,                            XF86XK_AudioPlay,         spawn,          {.v = media_play } },    /* Play/Pause */
	{ 0,                            XF86XK_AudioPause,        spawn,          {.v = media_play } },    /* Pause (same as play) */
	{ 0,                            XF86XK_AudioNext,         spawn,          {.v = media_next } },    /* Next track */
	{ 0,                            XF86XK_AudioPrev,         spawn,          {.v = media_prev } },    /* Previous track */

	/* Hardware keys - Display & AI */
	{ 0,                            XF86XK_Display,           spawn,          {.v = arandrcmd } },          /* F1/Display -> arandr */

	/* Wallpaper */
	{ MODKEY|ShiftMask,             XK_w,                     spawn,          {.v = wallnext } },      /* Super+Shift+W -> next wallpaper */

	/* Screenshots */
	{ 0,                            XK_Print,                 spawn,          {.v = ss_select } },     /* Print -> screenshot with prompt */
	{ MODKEY,                       XK_Print,                 spawn,          {.v = ss_full } },       /* Super+Print -> full screen */
	{ MODKEY|ControlMask,           XK_Print,                 spawn,          {.v = capturecmd } },    /* Super+Ctrl+Print -> capture menu */
	{ MODKEY|ShiftMask,             XK_Print,                 spawn,          {.v = ss_flameshot } },  /* Super+Shift+Print -> flameshot gui */
	{ MODKEY|Mod1Mask,              XK_s,                     spawn,          {.v = ss_browser } },    /* Super+Alt+S -> browse screenshots */
};

/*========================
  Mouse buttons
=========================*/
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button3,        spawn,          {.v = statuscmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        dragmfact,      {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

/* X resources (dwm.*) that override the compiled fonts/colors at runtime.
 * nirupi writes ~/.config/nirupi/xresources.noir and merges it via xrdb. */
static const XResPref resources[] = {
	{ "dwm.font",          STRING,  &fonts[0] },
	{ "dwm.foreground",    STRING,  &colors[SchemeNorm][ColFg] },
	{ "dwm.background",    STRING,  &colors[SchemeNorm][ColBg] },
	{ "dwm.border",        STRING,  &colors[SchemeNorm][ColBorder] },
	{ "dwm.foregroundSel", STRING,  &colors[SchemeSel][ColFg] },
	{ "dwm.backgroundSel", STRING,  &colors[SchemeSel][ColBg] },
	{ "dwm.borderSel",     STRING,  &colors[SchemeSel][ColBorder] },
};
