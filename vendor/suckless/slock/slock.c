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
	char lastclock[48];
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
static XftColor clkfg, clkdim;
static char hostnamebuf[HOST_NAME_MAX + 1];

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
	XftColorAllocName(dpy, DefaultVisual(dpy, screen),
	                  DefaultColormap(dpy, screen), clockforeground, &clkfg);
	XftColorAllocName(dpy, DefaultVisual(dpy, screen),
	                  DefaultColormap(dpy, screen), clockdim, &clkdim);
}

/* Draw time (big) + date + hostname (dim) centred on the locked window. */
static void
drawclock(Display *dpy, struct lock *lock, int force)
{
	char tim[8], date[32], stamp[48];
	time_t t = time(NULL);
	struct tm *tm = localtime(&t);
	XGlyphInfo ext;
	int sw, sh, y;

	if (!lock->xftdraw || !clkfont)
		return;
	sw = DisplayWidth(dpy, lock->screen);
	sh = DisplayHeight(dpy, lock->screen);
	strftime(tim, sizeof tim, "%H:%M", tm);
	strftime(date, sizeof date, "%A %d %B", tm);
	snprintf(stamp, sizeof stamp, "%s %s", tim, date);
	if (!force && !strcmp(stamp, lock->lastclock))
		return;
	snprintf(lock->lastclock, sizeof lock->lastclock, "%s", stamp);

	XClearWindow(dpy, lock->win);

	XftTextExtentsUtf8(dpy, clkfont, (FcChar8 *)tim, strlen(tim), &ext);
	XftDrawStringUtf8(lock->xftdraw, &clkfg, clkfont,
	                  (sw - ext.xOff) / 2, sh / 2 + clkfont->ascent / 2, (FcChar8 *)tim, strlen(tim));

	y = sh / 2 + clkfont->ascent / 2 + 24;
	if (clkfontsmall) {
		int smasc = clkfontsmall->ascent;
		XftTextExtentsUtf8(dpy, clkfontsmall, (FcChar8 *)date, strlen(date), &ext);
		XftDrawStringUtf8(lock->xftdraw, &clkdim, clkfontsmall,
		                  (sw - ext.xOff) / 2, y + smasc, (FcChar8 *)date, strlen(date));
		if (hostnamebuf[0]) {
			XftTextExtentsUtf8(dpy, clkfontsmall, (FcChar8 *)hostnamebuf, strlen(hostnamebuf), &ext);
			XftDrawStringUtf8(lock->xftdraw, &clkdim, clkfontsmall,
			                  (sw - ext.xOff) / 2, y + smasc + clkfontsmall->height + 4,
			                  (FcChar8 *)hostnamebuf, strlen(hostnamebuf));
		}
	}
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
				drawclock(dpy, locks[screen], 0);
			continue;
		}
		XNextEvent(dpy, &ev);
		if (ev.type == KeyPress) {
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
					drawclock(dpy, locks[screen], 1);
				oldc = color;
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
					break;
				}
			}
		} else if (ev.type == Expose) {
			for (screen = 0; screen < nscreens; screen++)
				drawclock(dpy, locks[screen], 1);
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
    if(lock->bgmap)
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
			drawclock(dpy, lock, 1);
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
	die("usage: slock [-v] [cmd [arg ...]]\n");
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
	default:
		usage();
	} ARGEND

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

	/*Create screenshot Image*/
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
