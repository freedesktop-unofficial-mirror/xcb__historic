/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Status XAllocColor(register Display *dpy, Colormap cmap, XColor *def)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBAllocColorRep *r;

    r = XCBAllocColorReply(c, XCBAllocColor(c, XCLCOLORMAP(cmap), def->red, def->green, def->blue), 0);
    if (!r)
	return 0;

    def->red = r->red;
    def->green = r->green;
    def->blue = r->blue;
    def->pixel = r->pixel;
    free(r);
    return 1;
}
