/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XResizeWindow(register Display *dpy, Window w, unsigned int width, unsigned int height)
{
    CARD32 values[] = { width, height };
    XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWWidth | CWHeight, values);
    return 1;
}
