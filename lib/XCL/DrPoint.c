/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XDrawPoint(Display *dpy, Drawable d, GC gc, int x, int y)
{
    POINT p = { x, y };

    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBPolyPoint(XCBConnectionOfDisplay(dpy), CoordModeOrigin, XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), 1, &p);
    UnlockDisplay(dpy);
    return 1;
}
