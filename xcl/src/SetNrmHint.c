/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * Portions Copyright 1988 by Wyse Technology, Inc., San Jose, Ca
 * Portions Copyright 1987 by Digital Equipment Corporation,
 * Maynard, Massachusetts
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/Xos.h>

void XSetWMSizeHints(Display *dpy, Window w, XSizeHints *hints, Atom prop)
{
    hints->flags &= USPosition|USSize|PPosition|PSize|PMinSize|PMaxSize|
		   PResizeInc|PAspect|PBaseSize|PWinGravity;
    XCBChangeProperty(XCBConnectionOfDisplay(dpy), PropModeReplace, XCLWINDOW(w), XCLATOM(prop), XCLATOM(XA_WM_SIZE_HINTS), 32, sizeof(*hints) >> 2, hints);
}

void XSetWMNormalHints(Display *dpy, Window w, XSizeHints *hints)
{
    XSetWMSizeHints(dpy, w, hints, XA_WM_NORMAL_HINTS);
}
