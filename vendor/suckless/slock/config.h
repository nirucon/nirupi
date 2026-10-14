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
