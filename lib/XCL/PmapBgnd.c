/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XSetWindowBackgroundPixmap(Display *dpy, Window w, Pixmap pixmap)
{
	CARD32 values[] = { pixmap };
	XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWBackPixmap, values);
	return 1;
}
