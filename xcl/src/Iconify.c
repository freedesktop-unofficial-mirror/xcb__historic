/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1988, 1998  The Open Group
 * Copyright 1988 by Wyse Technology, Inc., San Jose, Ca.
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xatom.h>
#include <X11/Xutil.h>

/*
 * This function instructs the window manager to change this window from
 * NormalState to IconicState.
 */
Status XIconifyWindow(Display *dpy, Window w, int screen)
{
    XClientMessageEvent ev;
    Atom prop;

    prop = XInternAtom(dpy, "WM_CHANGE_STATE", False);
    if(prop == None)
	return False;

    ev.type = ClientMessage;
    ev.window = w;
    ev.message_type = prop;
    ev.format = 32;
    ev.data.l[0] = IconicState;
    return XSendEvent(dpy, RootWindow(dpy, screen), False,
			SubstructureRedirectMask|SubstructureNotifyMask,
			(XEvent *)&ev);
}
