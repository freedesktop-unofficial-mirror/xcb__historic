/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/XCB/xcb_event.h>
#include <assert.h>
#include <unistd.h>

static int _XHandleInternalEvent(Display *dpy, XCBGenericEvent *e)
{
	if(e->response_type == X_Error)
	{
		_XError(dpy, (xError *) e);
		return 1;
	}
	return 0;
}

/* Return next event in queue, or if none, flush output and wait for events. */
int XNextEvent(Display *dpy, register XEvent *event)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBGenericEvent *e;

	if(XCBEventQueueIsEmpty(c))
		XCBFlush(c);

	do
		e = XCBWaitEvent(c);
	while(_XHandleInternalEvent(dpy, e) || !(*dpy->event_vec[e->response_type & 0177])(dpy, event, (xEvent *) e));

	return 0;
}
