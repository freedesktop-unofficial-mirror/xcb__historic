/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XBell(register Display *dpy, int percent)
{
    XCBBell(XCBConnectionOfDisplay(dpy), percent);
    return 1;
}

