#include "xclint.h"

int XSetFont(register Display *dpy, GC gc, Font font)
{
    LockDisplay(dpy);
    if (gc->values.font != font) {
	gc->values.font = font;
	gc->dirty |= GCFont;
	_XFlushGCCache(dpy, gc);
    }
    UnlockDisplay(dpy);
    return 1;
}
