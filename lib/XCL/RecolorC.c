/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XRecolorCursor(register Display *dpy, Cursor cursor, XColor *foreground, XColor *background)
{       
    XCBRecolorCursor(XCBConnectionOfDisplay(dpy), XCLCURSOR(cursor),
		    foreground->red,
		    foreground->green,
		    foreground->blue,
		    background->red,
		    background->green,
		    background->blue);
	
    return 1;
}

