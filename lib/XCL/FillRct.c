/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XFillRectangle(register Display *dpy, Drawable d, GC gc, int x, int y, unsigned int width, unsigned int height)
{
    RECTANGLE r = { x, y, width, height };

    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBPolyFillRectangle(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), 1, &r);
    UnlockDisplay(dpy);
    return 1;
}
