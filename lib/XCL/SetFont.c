/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
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
