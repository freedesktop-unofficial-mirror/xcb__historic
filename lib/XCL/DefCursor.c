/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XDefineCursor(register Display *dpy, Window w, Cursor cursor)
{
    CARD32 values[] = { cursor };
    XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWCursor, values);
    return 1;
}

