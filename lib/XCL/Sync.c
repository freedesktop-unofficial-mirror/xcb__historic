/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <xcb_event.h>

/* Synchronize with errors and events, optionally discarding pending events */
int XSync(Display *dpy, Bool discard)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBSync(c, 0);
    if(discard)
	XCBEventQueueClear(c);
    return 1;
}
