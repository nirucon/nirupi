/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "black",     /* after initialization */
	[INPUT] =  "#005577",   /* during input */
	[FAILED] = "#CC3333",   /* wrong password */
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

/* NIRU Noir lock-screen clock (big time, dim date/hostname over the blur). */
static const char *clockfont          = "JetBrainsMono Nerd Font:size=54";
static const char *clockfontsmall     = "JetBrainsMono Nerd Font:size=14";
static const char *clockforeground    = "#e5e5e5";
static const char *clockdim           = "#8a8a8a";

static const char *clockshadow        = "#0f0f10";

/* Screensaver (slock -s): Elder Futhark runes alternating with ASCII. */
static const char *runefont           = "Noto Sans Runic:size=54";
static const char *runefontsmall      = "Noto Sans Runic:size=16";
