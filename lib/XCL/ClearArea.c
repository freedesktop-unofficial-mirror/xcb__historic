/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XClearArea(register Display *dpy, Window w, int x, int y, unsigned int width, unsigned int height, Bool exposures)
{
    XCBClearArea(XCBConnectionOfDisplay(dpy), exposures, XCLWINDOW(w), x, y, width, height);
    return 1;
}

