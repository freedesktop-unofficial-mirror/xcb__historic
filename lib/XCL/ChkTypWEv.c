/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1985, 1987, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <xcb_event.h>

/* It doesn't matter how this struct is packed by the compiler. */
typedef struct
{
	BYTE response_type;
	Window w;
	Display *dpy;
	Bool (*event_proc)(Display *, XEvent *, xEvent *);
	XEvent *e;
} TypeWindowEvent;

static int MatchTypeWindowEvent(const XCBGenericEvent *l, const XCBGenericEvent *r)
{
	TypeWindowEvent *tw;
	xEvent *xev;
	if(l->response_type != r->response_type)
		return 0;

	/* FIXME: breaks encapsulation: relies on r being the queued item */
	tw = (TypeWindowEvent *) l;
	xev = (xEvent *) r;

	if(!tw->event_proc(tw->dpy, tw->e, xev))
		return 0;
	if(tw->w != tw->e->xany.window)
		return 0;
	return 1;
}

/* Check events for a match, without blocking. */
/* w: Selected window. */
/* type: Selected event type. */
/* event: XEvent to be filled in. */
Bool XCheckTypedWindowEvent(Display *dpy, Window w, int type, XEvent *event)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	TypeWindowEvent tw = { type, w, dpy, dpy->event_vec[type & 0177], event };
	XCBGenericEvent *ret;

	_XEventsQueued(dpy, QueuedAfterFlush);
	ret = XCBEventQueueRemove(c, MatchTypeWindowEvent, (XCBGenericEvent *) &tw);
	if(!ret)
		return False;
	free(ret);
	return True;
}
