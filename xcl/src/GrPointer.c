/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XGrabPointer(Display *dpy, Window grab_window, Bool owner_events,
    unsigned int event_mask, /* CARD16 */
    int pointer_mode, int keyboard_mode, Window confine_to, Cursor curs, Time time)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGrabPointerRep *r;
    register int status;

    r = XCBGrabPointerReply(c, XCBGrabPointer(c, owner_events, XCLWINDOW(grab_window), event_mask, pointer_mode, keyboard_mode, XCLWINDOW(confine_to), XCLCURSOR(curs), XCLTIMESTAMP(time)), 0);

    /* Xlib says: "if we ever return, suppress the error" */
    if(!r)
	status = GrabSuccess;
    else
	status = r->status;
    free(r);
    return status;
}
