/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"monospace:size=10"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#a8a8a8", "#0f0f10" },
	[SchemeSel]  = { "#e5e5e5", "#3a3a3d" },
	[SchemeOut]  = { "#0f0f10", "#a8a8a8" },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";


/* X resources loaded at startup (see lib/theme.sh -> xresources.noir). */
static const XResPref resources[] = {
	/* name                  type     address */
	{ "dmenu.font",          STRING,  &fonts[0] },
	{ "dmenu.prompt",        STRING,  &prompt },
	{ "dmenu.foreground",    STRING,  &colors[SchemeNorm][ColFg] },
	{ "dmenu.background",    STRING,  &colors[SchemeNorm][ColBg] },
	{ "dmenu.selforeground", STRING,  &colors[SchemeSel][ColFg] },
	{ "dmenu.selbackground", STRING,  &colors[SchemeSel][ColBg] },
	{ "dmenu.foregroundOut", STRING,  &colors[SchemeOut][ColFg] },
	{ "dmenu.backgroundOut", STRING,  &colors[SchemeOut][ColBg] },
	{ "dmenu.topbar",        INTEGER, &topbar },
	{ "dmenu.lines",         INTEGER, &lines },
};
