/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Status XQueryTree(Display *dpy, Window w, Window *root, Window *parent, Window **children, unsigned int *nchildren)
{
	XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBQueryTreeRep *r;

	r = XCBQueryTreeReply(c, XCBQueryTree(c, XCLWINDOW(w)), 0);
	if(!r)
		return 0;

	*children = 0;
	*root = r->root.xid;
	*parent = r->parent.xid;
	*nchildren = r->children_len;
	if(*nchildren <= 0)
		return 1;

	/* reuse the memory chunk the reply came in. */
	memmove(r, XCBQueryTreechildren(r), *nchildren * sizeof(WINDOW));
	*children = (Window *) r;
	return 1;
}
