/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Bool XQueryPointer(register Display *dpy, Window w, Window *root, Window *child,
    int *root_x, int *root_y, int *win_x, int *win_y, unsigned int *mask)
{       
    XCBQueryPointerCookie c;
    XCBQueryPointerRep *r;
    BOOL same_screen;

    c = XCBQueryPointer(XCBConnectionOfDisplay(dpy), XCLWINDOW(w));
    r = XCBQueryPointerReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!r)
	    return False;

    *root = r->root.xid;
    *child = r->child.xid;
    *root_x = (int)r->root_x;
    *root_y = (int)r->root_y;
    *win_x = (int)r->win_x;
    *win_y = (int)r->win_y;
    *mask = (unsigned int)r->mask;
    same_screen = r->same_screen;
    free(r);
    return same_screen;
}

