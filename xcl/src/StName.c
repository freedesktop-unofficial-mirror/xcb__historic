/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xatom.h>

int XStoreName(register Display *dpy, Window w, const char *name)
{
    XCBChangeProperty(XCBConnectionOfDisplay(dpy), PropModeReplace, XCLWINDOW(w), XCLATOM(XA_WM_NAME), XCLATOM(XA_STRING), 8, name ? strlen(name) : 0, name);
    return 1;
}

int XSetIconName(register Display *dpy, Window w, const char *icon_name)
{
    return XChangeProperty(dpy, w, XA_WM_ICON_NAME, XA_STRING, 
			   8, PropModeReplace, (unsigned char *)icon_name,
			   icon_name ? strlen(icon_name) : 0);
}
