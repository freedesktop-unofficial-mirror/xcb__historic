#include "xclint.h"

/* in ChGC.c */
extern int _XUpdateGCCache(register GC gc, register unsigned long mask, register XGCValues *attr);

int XChangeGC(register Display *dpy, GC gc, unsigned long mask, XGCValues *values)
{
    LockDisplay(dpy);
    mask &= (1L << (GCLastBit + 1)) - 1;
    if (mask) _XUpdateGCCache (gc, mask, values);

    /* if any Resource ID changed, must flush */
    if (gc->dirty & (GCFont | GCTile | GCStipple))
	_XFlushGCCache(dpy, gc);
    UnlockDisplay(dpy);
    return 1;
}

