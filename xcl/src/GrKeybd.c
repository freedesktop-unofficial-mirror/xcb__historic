/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XGrabKeyboard (dpy, window, ownerEvents, pointerMode, keyboardMode, time)
    register Display *dpy;
    Window window;
    Bool ownerEvents;
    int pointerMode, keyboardMode;
    Time time;
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGrabKeyboardRep *r;
    register int status;

    r = XCBGrabKeyboardReply(c, XCBGrabKeyboard(c, ownerEvents, XCLWINDOW(window), XCLTIMESTAMP(time), pointerMode, keyboardMode), 0);

    /* Xlib says: "if we ever return, suppress the error" */
    if(!r)
	status = GrabSuccess;
    else
	status = r->status;
    free(r);
    return status;
}
