/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Colormap XCreateColormap(Display *dpy, Window w, Visual *visual, int alloc)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	COLORMAP mid = XCBCOLORMAPNew(c);
	VisualID v;

	if(visual == CopyFromParent)
		v = CopyFromParent;
	else
		v = visual->visualid;

	XCBCreateColormap(c, alloc, mid, XCLWINDOW(w), XCLVISUALID(v));
	return mid.xid;
}
