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
	Display *dpy;
	Bool (*predicate)(Display*, XEvent*, char*);
	XEvent *e;
	char *arg;
} IfEvent;

static int MatchIfEvent(const XCBGenericEvent *l, const XCBGenericEvent *r)
{
	IfEvent *tw;
	xEvent *xev;

	/* FIXME: breaks encapsulation: relies on r being the queued item */
	tw = (IfEvent *) l;
	xev = (xEvent *) r;

	if(!tw->dpy->event_vec[r->response_type & 0177](tw->dpy, tw->e, xev))
		return 0;
	if(!tw->predicate(tw->dpy, tw->e, tw->arg))
		return 0;
	return 1;
}

/* Flush output and (wait for and) return the next event matching the
 * predicate in the queue. */
int XIfEvent(dpy, event, predicate, arg)
	Display *dpy;
	Bool (*predicate)(Display*, XEvent*, char*);
	register XEvent *event;
	char *arg;
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	IfEvent earg = { dpy, predicate, event, arg };
	XCBGenericEvent *eargp = (XCBGenericEvent *) &earg;
	XCBGenericEvent *ret;

	while(1)
	{
		ret = XCBEventQueueRemove(c, MatchIfEvent, eargp);
		if(ret)
			break;
		XCBWait(c->handle, /* should_write */ 1);
	}
	free(ret);
	return 0;
}
