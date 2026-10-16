/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

/* NIRU Noir lock screen palette (mirrors vendor/noir/theme/tokens.env). */
static const char *colorname[NUMCOLS] = {
	[INIT] =   "#0f0f10",   /* after initialization */
	[INPUT] =  "#3a3a3d",   /* during input */
	[FAILED] = "#b87878",   /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/*Enable blur*/
#define BLUR
/*Set blur radius*/
static const int blurRadius=5;
/*Enable Pixelation*/
//#define PIXELATION
/*Set pixelation radius*/
static const int pixelSize=0;

/* NIRU Noir lock-screen clock. Big time, then date and hostname in a dim tone,
 * centred over the blurred root. Requires Xft (see config.mk). */
static const char *clockfont          = "JetBrainsMono Nerd Font:size=54";
static const char *clockfontsmall     = "JetBrainsMono Nerd Font:size=14";
static const char *clockforeground    = "#e5e5e5";
static const char *clockdim           = "#8a8a8a";

static const char *clockshadow        = "#0f0f10";

/* Screensaver slideshow: pictures from this directory are shown (one per
 * monitor, randomly chosen, changing every SLIDESHOW_INTERVAL seconds) while
 * the screensaver face is visible. When the directory is missing or has no
 * usable image the screensaver keeps its plain look. */
static const char *slideshow_dir      = "Pictures/Screensaver";
static const int   slideshow_interval = 60;   /* seconds between changes */
static const int   slideshow_max      = 512;  /* directory scan cap */

/* Screensaver (slock -s): Elder Futhark runes alternating with ASCII. */
static const char *runefont           = "Noto Sans Runic:size=54";
static const char *runefontsmall      = "Noto Sans Runic:size=16";
