/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XUnmapWindow(register Display *dpy, Window w)
{
    XCBUnmapWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w));
    return 1;
}

