/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XRaiseWindow(Display *const dpy, const Window w)
{
	const static CARD32 values[] = { Above };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWStackMode, values);
	return 1;
}

int XLowerWindow(Display *const dpy, const Window w)
{
	const static CARD32 values[] = { Below };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWStackMode, values);
	return 1;
}
