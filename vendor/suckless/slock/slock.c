/* See LICENSE file for license details. */
#define _XOPEN_SOURCE 500
#if HAVE_SHADOW_H
#include <shadow.h>
#endif

#include <ctype.h>
#include <errno.h>
#include <grp.h>
#include <pwd.h>
#include <time.h>
#include <limits.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/types.h>
#include <sys/select.h>
#include <sys/time.h>
#include <X11/extensions/Xrandr.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xresource.h>
#include <X11/Xft/Xft.h>
#include <Imlib2.h>

#include "arg.h"
#include "util.h"

char *argv0;

enum {
	INIT,
	INPUT,
	FAILED,
	NUMCOLS
};

struct lock {
	int screen;
	Window root, win;
	Pixmap pmap;
	Pixmap bgmap;
	unsigned long colors[NUMCOLS];
	XftDraw *xftdraw;
	char lastclock[128];
};

struct xrandr {
	int active;
	int evbase;
	int errbase;
};

#include "config.h"

Imlib_Image image;

/* NIRU Noir lock-screen clock (Xft). */
static XftFont *clkfont, *clkfontsmall;
static XftFont *runicfont, *runicfontsmall;
static XftColor clkfg, clkdim, clkshadow;
static char hostnamebuf[HOST_NAME_MAX + 1];
static int screensaver = 0;   /* -s: show the screensaver first, lock on input */
static int woken = 0;         /* set once the screensaver receives its first input */
static time_t lockstart;      /* start time for the AFK timer */

static void
die(const char *errstr, ...)
{
	va_list ap;

	va_start(ap, errstr);
	vfprintf(stderr, errstr, ap);
	va_end(ap);
	exit(1);
}

#ifdef __linux__
#include <fcntl.h>
#include <linux/oom.h>

static void
dontkillme(void)
{
	FILE *f;
	const char oomfile[] = "/proc/self/oom_score_adj";

	if (!(f = fopen(oomfile, "w"))) {
		if (errno == ENOENT)
			return;
		die("slock: fopen %s: %s\n", oomfile, strerror(errno));
	}
	fprintf(f, "%d", OOM_SCORE_ADJ_MIN);
	if (fclose(f)) {
		if (errno == EACCES)
			die("slock: unable to disable OOM killer. "
			    "Make sure to suid or sgid slock.\n");
		else
			die("slock: fclose %s: %s\n", oomfile, strerror(errno));
	}
}
#endif

static const char *
gethash(void)
{
	const char *hash;
	struct passwd *pw;

	/* Check if the current user has a password entry */
	errno = 0;
	if (!(pw = getpwuid(getuid()))) {
		if (errno)
			die("slock: getpwuid: %s\n", strerror(errno));
		else
			die("slock: cannot retrieve password entry\n");
	}
	hash = pw->pw_passwd;

#if HAVE_SHADOW_H
	if (!strcmp(hash, "x")) {
		struct spwd *sp;
		if (!(sp = getspnam(pw->pw_name)))
			die("slock: getspnam: cannot retrieve shadow entry. "
			    "Make sure to suid or sgid slock.\n");
		hash = sp->sp_pwdp;
	}
#else
	if (!strcmp(hash, "*")) {
#ifdef __OpenBSD__
		if (!(pw = getpwuid_shadow(getuid())))
			die("slock: getpwnam_shadow: cannot retrieve shadow entry. "
			    "Make sure to suid or sgid slock.\n");
		hash = pw->pw_passwd;
#else
		die("slock: getpwuid: cannot retrieve shadow entry. "
		    "Make sure to suid or sgid slock.\n");
#endif /* __OpenBSD__ */
	}
#endif /* HAVE_SHADOW_H */

	return hash;
}

static void
initclock(Display *dpy)
{
	int screen = DefaultScreen(dpy);

	if (!(clkfont = XftFontOpenName(dpy, screen, clockfont)))
		return;
	clkfontsmall = XftFontOpenName(dpy, screen, clockfontsmall);
	runicfont = XftFontOpenName(dpy, screen, runefont);
	runicfontsmall = XftFontOpenName(dpy, screen, runefontsmall);
	XftColorAllocName(dpy, DefaultVisual(dpy, screen),
	                  DefaultColormap(dpy, screen), clockforeground, &clkfg);
	XftColorAllocName(dpy, DefaultVisual(dpy, screen),
	                  DefaultColormap(dpy, screen), clockdim, &clkdim);
	XftColorAllocName(dpy, DefaultVisual(dpy, screen),
	                  DefaultColormap(dpy, screen), clockshadow, &clkshadow);
}

/* Override the compiled palette/fonts from Xresources (slock.*), so a NIRUPI
 * theme switch also reaches the lock screen without a rebuild. */
static void
xresload(Display *dpy)
{
	XrmDatabase db;
	XrmValue value;
	char *type, *resm, *copy;

	if (!(resm = XResourceManagerString(dpy)))
		return;
	db = XrmGetStringDatabase(resm);
	if (!db)
		return;
#define XRES(name, dst) do { \
	if (XrmGetResource(db, (name), NULL, &type, &value) && value.addr) { \
		copy = strdup(value.addr); \
		if (copy) (dst) = copy; \
	} \
} while (0)
	XRES("slock.init", colorname[INIT]);
	XRES("slock.input", colorname[INPUT]);
	XRES("slock.failed", colorname[FAILED]);
	XRES("slock.clockForeground", clockforeground);
	XRES("slock.clockDim", clockdim);
	XRES("slock.clockShadow", clockshadow);
	XRES("slock.clockFont", clockfont);
	XRES("slock.clockFontSmall", clockfontsmall);
	XRES("slock.runeFont", runefont);
	XRES("slock.runeFontSmall", runefontsmall);
#undef XRES
	XrmDestroyDatabase(db);
}

/* Draw text with a subtle 1px dark halo so it stays readable on any blur. */
static void
drawtext(struct lock *lock, XftFont *f, XftColor *c, int x, int y, const char *s)
{
	int n = strlen(s);
	XftDrawStringUtf8(lock->xftdraw, &clkshadow, f, x + 1, y + 1, (FcChar8 *)s, n);
	XftDrawStringUtf8(lock->xftdraw, &clkshadow, f, x - 1, y - 1, (FcChar8 *)s, n);
	XftDrawStringUtf8(lock->xftdraw, c, f, x, y, (FcChar8 *)s, n);
}

/* Elder Futhark mapping for the screensaver (ASCII -> rune, UTF-8). */
static const char *
rune_for(unsigned char c)
{
	switch (tolower(c)) {
	case 'a': return "\u16a8"; case 'b': return "\u16d2"; case 'c': return "\u16b2";
	case 'd': return "\u16de"; case 'e': return "\u16d6"; case 'f': return "\u16a0";
	case 'g': return "\u16b7"; case 'h': return "\u16bb"; case 'i': return "\u16c1";
	case 'j': return "\u16c3"; case 'k': return "\u16b2"; case 'l': return "\u16da";
	case 'm': return "\u16d7"; case 'n': return "\u16be"; case 'o': return "\u16df";
	case 'p': return "\u16c8"; case 'q': return "\u16b2"; case 'r': return "\u16b1";
	case 's': return "\u16ca"; case 't': return "\u16cf"; case 'u': return "\u16a2";
	case 'v': return "\u16b9"; case 'w': return "\u16b9"; case 'x': return "\u16ca";
	case 'y': return "\u16c3"; case 'z': return "\u16c9";
	case '0': return "\u16a0"; case '1': return "\u16a2"; case '2': return "\u16a6";
	case '3': return "\u16a8"; case '4': return "\u16b1"; case '5': return "\u16b2";
	case '6': return "\u16b7"; case '7': return "\u16b9"; case '8': return "\u16ba";
	case '9': return "\u16be"; case ':': return "\u16ec";
	case '-': case '.': return "\u16eb"; case ' ': return " ";
	default: return NULL;
	}
}

static void
runify(const char *in, char *out, size_t outsz)
{
	const char *r;
	size_t o = 0;
	for (; *in && o + 4 < outsz; in++) {
		r = rune_for((unsigned char)*in);
		if (r) {
			size_t l = strlen(r);
			memcpy(out + o, r, l);
			o += l;
		} else {
			out[o++] = *in;
		}
	}
	out[o] = '\0';
}

/* Monitor list (RandR) so the clock can be centred on each physical screen
 * instead of the middle of the whole X screen. Cached; refreshed on RandR
 * change. Falls back to the X screen when RandR reports no monitors. */
struct moninfo { int x, y, w, h; };

static struct moninfo *mons = NULL;
static int nmons = 0;

static void
refreshmonitors(Display *dpy, struct lock *lock)
{
	XRRMonitorInfo *rm;
	int i, n = 0;

	if (mons) {
		free(mons);
		mons = NULL;
		nmons = 0;
	}
	rm = XRRGetMonitors(dpy, lock->root, True, &n);
	if (rm && n > 0) {
		mons = calloc(n, sizeof(struct moninfo));
		if (mons) {
			for (i = 0; i < n; i++) {
				mons[i].x = rm[i].x;
				mons[i].y = rm[i].y;
				mons[i].w = rm[i].width;
				mons[i].h = rm[i].height;
			}
			nmons = n;
		}
		XRRFreeMonitors(rm);
	}
	/* Fall back to the full X screen. */
	if (!mons) {
		mons = calloc(1, sizeof(struct moninfo));
		if (mons) {
			mons[0].x = 0;
			mons[0].y = 0;
			mons[0].w = DisplayWidth(dpy, lock->screen);
			mons[0].h = DisplayHeight(dpy, lock->screen);
			nmons = 1;
		}
	}
}

/* True when two monitors occupy the same area (mirrored/cloned output); we draw
 * such a pair only once so the clock is not double-printed. */
static int
duplicatemon(int i)
{
	int j;
	for (j = 0; j < i; j++)
		if (mons[j].x == mons[i].x && mons[j].y == mons[i].y &&
		    mons[j].w == mons[i].w && mons[j].h == mons[i].h)
			return 1;
	return 0;
}

/* Centre one line of text horizontally at baseline y, inside monitor `mon`. */
static void
centerline_mon(Display *dpy, struct lock *lock, XftFont *f, XftColor *c,
               int mon, int y, const char *s)
{
	XGlyphInfo ext;
	if (!f || !s || !*s || !mons || mon < 0 || mon >= nmons)
		return;
	XftTextExtentsUtf8(dpy, f, (FcChar8 *)s, strlen(s), &ext);
	drawtext(lock, f, c,
	         mons[mon].x + (mons[mon].w - ext.xOff) / 2, y, s);
}

/* Lock face: time, ISO date, hostname and an AFK timer, centred on every
 * physical monitor. */
static void
drawlock(Display *dpy, struct lock *lock, int force)
{
	char tim[8], date[16], afk[32], stamp[64];
	time_t t = time(NULL);
	struct tm *tm = localtime(&t);
	long secs = (long)(t - lockstart);
	int mon, y;

	if (!lock->xftdraw || !clkfont)
		return;
	refreshmonitors(dpy, lock);
	strftime(tim, sizeof tim, "%H:%M", tm);
	strftime(date, sizeof date, "%Y-%m-%d", tm);
	if (secs >= 3600)
		snprintf(afk, sizeof afk, "afk %ld:%02ld:%02ld", secs / 3600, (secs / 60) % 60, secs % 60);
	else
		snprintf(afk, sizeof afk, "afk %ld:%02ld", secs / 60, secs % 60);
	snprintf(stamp, sizeof stamp, "L %s %s %s", tim, date, afk);
	if (!force && !strcmp(stamp, lock->lastclock))
		return;
	snprintf(lock->lastclock, sizeof lock->lastclock, "%s", stamp);

	XClearWindow(dpy, lock->win);

	for (mon = 0; mon < nmons; mon++) {
		if (!mons || mons[mon].h <= 0 || duplicatemon(mon))
			continue;
		y = mons[mon].y + mons[mon].h / 2 + clkfont->ascent / 2;
		centerline_mon(dpy, lock, clkfont, &clkfg, mon, y, tim);
		if (clkfontsmall) {
			y += 24;
			centerline_mon(dpy, lock, clkfontsmall, &clkdim, mon,
			               y + clkfontsmall->ascent, date);
			y += clkfontsmall->height + 4;
			centerline_mon(dpy, lock, clkfontsmall, &clkdim, mon,
			               y + clkfontsmall->ascent, hostnamebuf);
			y += clkfontsmall->height + 4;
			centerline_mon(dpy, lock, clkfontsmall, &clkdim, mon,
			               y + clkfontsmall->ascent, afk);
		}
	}
}

/* Screensaver face: clock + hostname, alternating runes/ASCII every 30s,
 * centred on every physical monitor. */
static void
drawscreensaver(Display *dpy, struct lock *lock, int force)
{
	char tim[8], hostA[256], hostR[1024], stamp[64];
	time_t t = time(NULL);
	struct tm *tm = localtime(&t);
	int phase = (int)(((t - lockstart) / 30) % 2);
	int mon, y, i;

	if (!lock->xftdraw || !clkfont)
		return;
	refreshmonitors(dpy, lock);
	strftime(tim, sizeof tim, "%H:%M", tm);
	snprintf(stamp, sizeof stamp, "S %d %s", phase, tim);
	if (!force && !strcmp(stamp, lock->lastclock))
		return;
	snprintf(lock->lastclock, sizeof lock->lastclock, "%s", stamp);

	XClearWindow(dpy, lock->win);

	/* hostname: runes <-> uppercase ASCII, rotating every 30 seconds */
	runify(hostnamebuf, hostR, sizeof hostR);
	for (i = 0; hostnamebuf[i] && i < (int)sizeof(hostA) - 1; i++)
		hostA[i] = toupper((unsigned char)hostnamebuf[i]);
	hostA[i] = '\0';

	for (mon = 0; mon < nmons; mon++) {
		if (!mons || mons[mon].h <= 0 || duplicatemon(mon))
			continue;
		/* clock: always normal digits (never runes) */
		y = mons[mon].y + mons[mon].h / 2 + clkfont->ascent / 2 - clkfont->descent;
		centerline_mon(dpy, lock, clkfont, &clkfg, mon, y, tim);

		if (phase == 0 && runicfontsmall)
			centerline_mon(dpy, lock, runicfontsmall, &clkdim, mon,
			               y + clkfont->descent + runicfontsmall->height, hostR);
		else if (clkfontsmall)
			centerline_mon(dpy, lock, clkfontsmall, &clkdim, mon,
			               y + clkfont->descent + clkfontsmall->height + 4, hostA);
	}
}

/* Switch the screensaver over to the blurred lock face (first input). */
static void
applyblur(Display *dpy, struct lock *lock)
{
	if (lock->bgmap)
		XSetWindowBackgroundPixmap(dpy, lock->win, lock->bgmap);
	else
		XSetWindowBackground(dpy, lock->win, lock->colors[INIT]);
	XClearWindow(dpy, lock->win);
}

/* Choose the face: screensaver until the first input, then the lock. */
static void
redraw(Display *dpy, struct lock *lock, int force)
{
	if (screensaver && !woken)
		drawscreensaver(dpy, lock, force);
	else
		drawlock(dpy, lock, force);
}

static void
readpw(Display *dpy, struct xrandr *rr, struct lock **locks, int nscreens,
       const char *hash)
{
	XRRScreenChangeNotifyEvent *rre;
	char buf[32], passwd[256], *inputhash;
	int num, screen, running, failure, oldc;
	unsigned int len, color;
	KeySym ksym;
	XEvent ev;

	len = 0;
	running = 1;
	failure = 0;
	oldc = INIT;

	while (running) {
		if (!XPending(dpy)) {
			fd_set fds;
			struct timeval tv = { 1, 0 };
			FD_ZERO(&fds);
			FD_SET(ConnectionNumber(dpy), &fds);
			(void)select(ConnectionNumber(dpy) + 1, &fds, NULL, NULL, &tv);
			for (screen = 0; screen < nscreens; screen++)
				redraw(dpy, locks[screen], 0);
			continue;
		}
		XNextEvent(dpy, &ev);
		if (ev.type == KeyPress) {
			if (screensaver && !woken) { /* any key wakes the lock */
				woken = 1;
				for (screen = 0; screen < nscreens; screen++) {
					applyblur(dpy, locks[screen]);
					redraw(dpy, locks[screen], 1);
				}
				continue;
			}
			explicit_bzero(&buf, sizeof(buf));
			num = XLookupString(&ev.xkey, buf, sizeof(buf), &ksym, 0);
			if (IsKeypadKey(ksym)) {
				if (ksym == XK_KP_Enter)
					ksym = XK_Return;
				else if (ksym >= XK_KP_0 && ksym <= XK_KP_9)
					ksym = (ksym - XK_KP_0) + XK_0;
			}
			if (IsFunctionKey(ksym) ||
			    IsKeypadKey(ksym) ||
			    IsMiscFunctionKey(ksym) ||
			    IsPFKey(ksym) ||
			    IsPrivateKeypadKey(ksym))
				continue;
			switch (ksym) {
			case XK_Return:
				passwd[len] = '\0';
				errno = 0;
				if (!(inputhash = crypt(passwd, hash)))
					fprintf(stderr, "slock: crypt: %s\n", strerror(errno));
				else
					running = !!strcmp(inputhash, hash);
				if (running) {
					XBell(dpy, 100);
					failure = 1;
				}
				explicit_bzero(&passwd, sizeof(passwd));
				len = 0;
				break;
			case XK_Escape:
				explicit_bzero(&passwd, sizeof(passwd));
				len = 0;
				break;
			case XK_BackSpace:
				if (len)
					passwd[--len] = '\0';
				break;
			default:
				if (num && !iscntrl((unsigned char)buf[0]) &&
				    (len + num < sizeof(passwd))) {
					memcpy(passwd + len, buf, num);
					len += num;
				} else if (buf[0] == '\025') { /* ctrl-u clears input */
					explicit_bzero(&passwd, sizeof(passwd));
					len = 0;
				}
				break;
			}
			color = len ? INPUT : ((failure || failonclear) ? FAILED : INIT);
			if (running && oldc != color) {
				for (screen = 0; screen < nscreens; screen++) {
                    if(locks[screen]->bgmap)
                        XSetWindowBackgroundPixmap(dpy, locks[screen]->win, locks[screen]->bgmap);
                    else
                        XSetWindowBackground(dpy, locks[screen]->win, locks[screen]->colors[0]);
					XClearWindow(dpy, locks[screen]->win);
				}
				for (screen = 0; screen < nscreens; screen++)
					redraw(dpy, locks[screen], 1);
				oldc = color;
			}
		} else if ((ev.type == ButtonPress || ev.type == ButtonRelease) && screensaver && !woken) {
			woken = 1;
			for (screen = 0; screen < nscreens; screen++) {
				applyblur(dpy, locks[screen]);
				redraw(dpy, locks[screen], 1);
			}
		} else if (rr->active && ev.type == rr->evbase + RRScreenChangeNotify) {
			rre = (XRRScreenChangeNotifyEvent*)&ev;
			for (screen = 0; screen < nscreens; screen++) {
				if (locks[screen]->win == rre->window) {
					if (rre->rotation == RR_Rotate_90 ||
					    rre->rotation == RR_Rotate_270)
						XResizeWindow(dpy, locks[screen]->win,
						              rre->height, rre->width);
					else
						XResizeWindow(dpy, locks[screen]->win,
						              rre->width, rre->height);
					XClearWindow(dpy, locks[screen]->win);
					/* monitor layout changed: re-centre the clock */
					refreshmonitors(dpy, locks[screen]);
					redraw(dpy, locks[screen], 1);
					break;
				}
			}
		} else if (ev.type == Expose) {
			for (screen = 0; screen < nscreens; screen++)
				redraw(dpy, locks[screen], 1);
		} else {
			for (screen = 0; screen < nscreens; screen++)
				XRaiseWindow(dpy, locks[screen]->win);
		}
	}
}

static struct lock *
lockscreen(Display *dpy, struct xrandr *rr, int screen)
{
	char curs[] = {0, 0, 0, 0, 0, 0, 0, 0};
	int i, ptgrab, kbgrab;
	struct lock *lock;
	XColor color, dummy;
	XSetWindowAttributes wa;
	Cursor invisible;

	if (dpy == NULL || screen < 0 || !(lock = malloc(sizeof(struct lock))))
		return NULL;

	lock->screen = screen;
	lock->root = RootWindow(dpy, lock->screen);
	lock->bgmap = 0; /* screensaver mode has no blurred background */

    if(image) 
    {
        lock->bgmap = XCreatePixmap(dpy, lock->root, DisplayWidth(dpy, lock->screen), DisplayHeight(dpy, lock->screen), DefaultDepth(dpy, lock->screen));
        imlib_context_set_image(image);
        imlib_context_set_display(dpy);
        imlib_context_set_visual(DefaultVisual(dpy, lock->screen));
        imlib_context_set_colormap(DefaultColormap(dpy, lock->screen));
        imlib_context_set_drawable(lock->bgmap);
        imlib_render_image_on_drawable(0, 0);
        imlib_free_image();
    }
	for (i = 0; i < NUMCOLS; i++) {
		XAllocNamedColor(dpy, DefaultColormap(dpy, lock->screen),
		                 colorname[i], &color, &dummy);
		lock->colors[i] = color.pixel;
	}

	/* init */
	wa.override_redirect = 1;
	wa.background_pixel = lock->colors[INIT];
	wa.event_mask = ExposureMask;
	lock->win = XCreateWindow(dpy, lock->root, 0, 0,
	                          DisplayWidth(dpy, lock->screen),
	                          DisplayHeight(dpy, lock->screen),
	                          0, DefaultDepth(dpy, lock->screen),
	                          CopyFromParent,
	                          DefaultVisual(dpy, lock->screen),
	                          CWOverrideRedirect | CWBackPixel | CWEventMask, &wa);
    if(lock->bgmap && !screensaver)
        XSetWindowBackgroundPixmap(dpy, lock->win, lock->bgmap);
	lock->xftdraw = XftDrawCreate(dpy, lock->win,
	                              DefaultVisual(dpy, lock->screen),
	                              DefaultColormap(dpy, lock->screen));
	lock->lastclock[0] = '\0';
	lock->pmap = XCreateBitmapFromData(dpy, lock->win, curs, 8, 8);
	invisible = XCreatePixmapCursor(dpy, lock->pmap, lock->pmap,
	                                &color, &color, 0, 0);
	XDefineCursor(dpy, lock->win, invisible);

	/* Try to grab mouse pointer *and* keyboard for 600ms, else fail the lock */
	for (i = 0, ptgrab = kbgrab = -1; i < 6; i++) {
		if (ptgrab != GrabSuccess) {
			ptgrab = XGrabPointer(dpy, lock->root, False,
			                      ButtonPressMask | ButtonReleaseMask |
			                      PointerMotionMask, GrabModeAsync,
			                      GrabModeAsync, None, invisible, CurrentTime);
		}
		if (kbgrab != GrabSuccess) {
			kbgrab = XGrabKeyboard(dpy, lock->root, True,
			                       GrabModeAsync, GrabModeAsync, CurrentTime);
		}

		/* input is grabbed: we can lock the screen */
		if (ptgrab == GrabSuccess && kbgrab == GrabSuccess) {
			XMapRaised(dpy, lock->win);
			if (rr->active)
				XRRSelectInput(dpy, lock->win, RRScreenChangeNotifyMask);

			XSelectInput(dpy, lock->root, SubstructureNotifyMask);
			redraw(dpy, lock, 1);
			return lock;
		}

		/* retry on AlreadyGrabbed but fail on other errors */
		if ((ptgrab != AlreadyGrabbed && ptgrab != GrabSuccess) ||
		    (kbgrab != AlreadyGrabbed && kbgrab != GrabSuccess))
			break;

		usleep(100000);
	}

	/* we couldn't grab all input: fail out */
	if (ptgrab != GrabSuccess)
		fprintf(stderr, "slock: unable to grab mouse pointer for screen %d\n",
		        screen);
	if (kbgrab != GrabSuccess)
		fprintf(stderr, "slock: unable to grab keyboard for screen %d\n",
		        screen);
	return NULL;
}

static void
usage(void)
{
	die("usage: slock [-sv] [cmd [arg ...]]\n");
}

int
main(int argc, char **argv) {
	struct xrandr rr;
	struct lock **locks;
	struct passwd *pwd;
	struct group *grp;
	uid_t duid;
	gid_t dgid;
	const char *hash;
	Display *dpy;
	int s, nlocks, nscreens;

	ARGBEGIN {
	case 'v':
		puts("slock-"VERSION);
		return 0;
	case 's':
		screensaver = 1;
		break;
	default:
		usage();
	} ARGEND

	lockstart = time(NULL);

	/* validate drop-user and -group */
	errno = 0;
	if (!(pwd = getpwnam(user)))
		die("slock: getpwnam %s: %s\n", user,
		    errno ? strerror(errno) : "user entry not found");
	duid = pwd->pw_uid;
	errno = 0;
	if (!(grp = getgrnam(group))) {
		/* Some systems (e.g. Void) have no "nobody" group. Fall back to the
		 * drop-user's primary group instead of refusing to lock. */
		if (!(grp = getgrgid(pwd->pw_gid)))
			die("slock: getgrnam %s: %s\n", group,
			    errno ? strerror(errno) : "group entry not found");
	}
	dgid = grp->gr_gid;

#ifdef __linux__
	dontkillme();
#endif

	hash = gethash();
	errno = 0;
	if (!crypt("", hash))
		die("slock: crypt: %s\n", strerror(errno));

	if (!(dpy = XOpenDisplay(NULL)))
		die("slock: cannot open display\n");
	XrmInitialize();
	xresload(dpy);

	/* lock-screen clock: resolve fonts/colours before dropping privileges */
	if (gethostname(hostnamebuf, sizeof hostnamebuf - 1) != 0)
		hostnamebuf[0] = '\0';
	hostnamebuf[sizeof hostnamebuf - 1] = '\0';
	initclock(dpy);

	/* drop privileges */
	if (setgroups(0, NULL) < 0)
		die("slock: setgroups: %s\n", strerror(errno));
	if (setgid(dgid) < 0)
		die("slock: setgid: %s\n", strerror(errno));
	if (setuid(duid) < 0)
		die("slock: setuid: %s\n", strerror(errno));

	/* Blur a screenshot of the root; the lock face shows it (the screensaver
	 * keeps it in reserve and switches to it once the user returns). */
	Screen *scr = ScreenOfDisplay(dpy, DefaultScreen(dpy));
	image = imlib_create_image(scr->width,scr->height);
	imlib_context_set_image(image);
	imlib_context_set_display(dpy);
	imlib_context_set_visual(DefaultVisual(dpy,0));
	imlib_context_set_drawable(RootWindow(dpy,XScreenNumberOfScreen(scr)));	
	imlib_copy_drawable_to_image(0,0,0,scr->width,scr->height,0,0,1);

#ifdef BLUR

	/*Blur function*/
	imlib_image_blur(blurRadius);
#endif // BLUR	

#ifdef PIXELATION
	/*Pixelation*/
	int width = scr->width;
	int height = scr->height;
	
	for(int y = 0; y < height; y += pixelSize)
	{
		for(int x = 0; x < width; x += pixelSize)
		{
			int red = 0;
			int green = 0;
			int blue = 0;

			Imlib_Color pixel; 
			Imlib_Color* pp;
			pp = &pixel;
			for(int j = 0; j < pixelSize && j < height; j++)
			{
				for(int i = 0; i < pixelSize && i < width; i++)
				{
					imlib_image_query_pixel(x+i,y+j,pp);
					red += pixel.red;
					green += pixel.green;
					blue += pixel.blue;
				}
			}
			red /= (pixelSize*pixelSize);
			green /= (pixelSize*pixelSize);
			blue /= (pixelSize*pixelSize);
			imlib_context_set_color(red,green,blue,pixel.alpha);
			imlib_image_fill_rectangle(x,y,pixelSize,pixelSize);
			red = 0;
			green = 0;
			blue = 0;
		}
	}
	
	
#endif
	/* check for Xrandr support */
	rr.active = XRRQueryExtension(dpy, &rr.evbase, &rr.errbase);

	/* get number of screens in display "dpy" and blank them */
	nscreens = ScreenCount(dpy);
	if (!(locks = calloc(nscreens, sizeof(struct lock *))))
		die("slock: out of memory\n");
	for (nlocks = 0, s = 0; s < nscreens; s++) {
		if ((locks[s] = lockscreen(dpy, &rr, s)) != NULL)
			nlocks++;
		else
			break;
	}
	XSync(dpy, 0);

	/* did we manage to lock everything? */
	if (nlocks != nscreens)
		return 1;

	/* run post-lock command */
	if (argc > 0) {
		pid_t pid;
		extern char **environ;
		int err = posix_spawnp(&pid, argv[0], NULL, NULL, argv, environ);
		if (err) {
			die("slock: failed to execute post-lock command: %s: %s\n",
			    argv[0], strerror(err));
		}
	}

	/* everything is now blank. Wait for the correct password */
	readpw(dpy, &rr, locks, nscreens, hash);

	return 0;
}
