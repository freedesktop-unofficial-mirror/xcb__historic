/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XUnloadFont(Display *dpy, Font font)
{
	XCBCloseFont(XCBConnectionOfDisplay(dpy), XCLFONT(font));
	return 1;
}

