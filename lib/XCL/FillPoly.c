/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XFillPolygon(register Display *dpy, Drawable d, GC gc, XPoint *points, int n_points, int shape, int mode)
{
    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBFillPoly(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), shape, mode, n_points, (POINT *) points);
    UnlockDisplay(dpy);
    return 1;
}
