/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XClearWindow(register Display *dpy, Window w)
{
    /* (x, y, width, height) = 0 means "clear the entire window" */
    XCBClearArea(XCBConnectionOfDisplay(dpy), /*exposures*/ 0, XCLWINDOW(w), 0, 0, 0, 0);
    return 1;
}

