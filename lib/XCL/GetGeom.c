/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Status XGetGeometry(Display *dpy, Drawable d, Window *root, int *x, int *y,
    unsigned int *width, unsigned int *height, unsigned int *borderWidth, unsigned int *depth)
{
	XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBGetGeometryRep *r;

	r = XCBGetGeometryReply(c, XCBGetGeometry(c, XCLDRAWABLE(d)), 0);
	if(!r)
		return 0;
	*depth = r->depth;
	*root = r->root.xid;
	*x = cvtINT16toInt(r->x);
	*y = cvtINT16toInt(r->y);
	*width = r->width;
	*height = r->height;
	*borderWidth = r->border_width;
	free(r);
	return 1;
}
