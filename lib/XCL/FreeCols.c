/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XFreeColors(dpy, cmap, pixels, npixels, planes)
register Display *dpy;
Colormap cmap;
unsigned long *pixels; /* LISTofCARD32 */
int npixels;
unsigned long planes; /* CARD32 */
{
	XCBFreeColors(XCBConnectionOfDisplay(dpy), XCLCOLORMAP(cmap), planes, (CARD32 *) pixels);
	return 1;
}

