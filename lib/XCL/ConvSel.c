/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XConvertSelection(register Display *dpy, Atom selection, Atom target, Atom property, Window requestor, Time time)
{
    XCBConvertSelection(XCBConnectionOfDisplay(dpy), XCLWINDOW(requestor), XCLATOM(selection), XCLATOM(target), XCLATOM(property), XCLTIMESTAMP(time));
    return 1;
}
