/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1988, 1998  The Open Group
 * Portions Copyright 1988 by Wyse Technology, Inc., San Jose, Ca
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xatom.h>
#include <X11/Xutil.h>

void XSetTextProperty(Display *dpy, Window w, XTextProperty *tp, Atom property)
{
    XChangeProperty(dpy, w, property, tp->encoding, tp->format, PropModeReplace, tp->value, tp->nitems);
}

void XSetWMName(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_NAME);
}

void XSetWMIconName(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_ICON_NAME);
}

void XSetWMClientMachine(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_CLIENT_MACHINE);
}
