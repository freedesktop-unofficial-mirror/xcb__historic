/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XSetWindowBackground(register Display *dpy, Window w, unsigned long pixel)
{
    CARD32 values[] = { pixel };
    XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWBackPixel, values);
    return 1;
}

