/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XMoveWindow(Display *const dpy, const Window w, const int x, const int y)
{
	CARD32 values[] = { x, y };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWX | CWY, values);
	return 1;
}
