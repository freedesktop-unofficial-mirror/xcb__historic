/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XReparentWindow(Display *dpy, Window w, Window p, int x, int y)
{
	XCBReparentWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), XCLWINDOW(p), x, y);
	return 1;
}
