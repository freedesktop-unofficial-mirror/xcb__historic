/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

/* Flush all buffered output requests. */
/* NOTE: NOT necessary when calling any of the Xlib routines. */

void _XFlush(register Display *dpy)
{
    XCBFlush(XCBConnectionOfDisplay(dpy));
}

int XFlush(register Display *dpy)
{
    XCBFlush(XCBConnectionOfDisplay(dpy));
    return 1;
}
