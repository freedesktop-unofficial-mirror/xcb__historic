/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/XCB/xcb_event.h>

/* Read in pending events if needed and return the number of queued events. */
int XEventsQueued(register Display *dpy, int mode)
{
    int ret = XCBEventQueueLength(XCBConnectionOfDisplay(dpy));
    if(!ret && mode != QueuedAlready)
	ret = _XEventsQueued(dpy, mode);
    return ret;
}

int XPending(Display *dpy)
{
    return XEventsQueued(dpy, QueuedAfterFlush);
}

int _XEventsQueued(register Display *dpy, int mode)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    if(mode == QueuedAfterFlush)
	XCBFlush(c);

    /* wait for handle to be readable, without blocking. */
    /* FIXME: this select/XCBWait hack breaks encapsulation. */
    if(XCBEventQueueIsEmpty(c))
    {
	fd_set fds;
	struct timeval tv = { 0, 0 };
	FD_ZERO(&fds);
	FD_SET(dpy->fd, &fds);
	if(select(dpy->fd + 1, &fds, 0, 0, &tv) < 1)
	    return 0;
	XCBWait(c->handle, /* should_write */ 0);
    }

    return XCBEventQueueLength(c);
}
