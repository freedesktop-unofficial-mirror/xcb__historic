/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Pixmap XCreatePixmap(Display *dpy, Drawable d, unsigned int width, unsigned int height, unsigned int depth)
{
	XCBConnection *c = XCBConnectionOfDisplay(dpy);
	PIXMAP p = XCBPIXMAPNew(c);
	XCBCreatePixmap(c, depth, p, XCLDRAWABLE(d), width, height);
	return p.xid;
}
