/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xatom.h>
// #include <X11/Xos.h>

static Status _XGetCStringProperty(register Display *dpy, Window w, ATOM property, char **name)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetPropertyRep *p;
    int len;

    p = XCBGetPropertyReply(c, XCBGetProperty(c, /* delete */ 0, XCLWINDOW(w), property, XCLATOM(XA_STRING), /* offset */ 0, /* length */ 1<<30), 0);

    if (!p || p->type.xid != XA_STRING || p->format != 8) {
	*name = NULL;
	free(p);
	return 0; /* failure */
    }

    len = XCBGetPropertyvalueLength(p);
    memmove(p, XCBGetPropertyvalue(p), len);
    *name = (char *) p;
    (*name)[len] = '\0';
    return 1; /* success */
}

Status XFetchName(Display *dpy, Window window, char **name)
{
    return _XGetCStringProperty(dpy, window, XCLATOM(XA_WM_NAME), name);
}

Status XGetIconName(Display *dpy, Window window, char **name)
{
    return _XGetCStringProperty(dpy, window, XCLATOM(XA_WM_ICON_NAME), name);
}
