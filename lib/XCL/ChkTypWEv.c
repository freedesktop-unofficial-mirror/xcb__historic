/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1985, 1987, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

static Bool _XCheckTypedWindowEvent(Display *dpy, const Window w, const int type, XEvent *event, register _XQEvent **prev)
{
	register _XQEvent *qelt = *prev ? (*prev)->next : dpy->head;
	register XEvent *e;
	while(qelt) {
		e = &qelt->event;
		if (e->xany.window == w && e->type == type) {
			*event = *e;
			_XDeq(dpy, *prev, qelt);
			UnlockDisplay(dpy);
			return True;
		}
		*prev = qelt;
		qelt = qelt->next;
	}
	return False;
}

/* Check existing events in queue to find if any match.  If so, return.
 * If not, flush buffer and see if any more events are readable. If one
 * matches, return.  If all else fails, tell the user no events found. */
/* w: Selected window. */
/* type: Selected event type. */
/* event: XEvent to be filled in. */
Bool XCheckTypedWindowEvent(Display *dpy, Window w, int type, XEvent *event)
{
	_XQEvent *prev = NULL;
	unsigned long qe_serial = 0;

        LockDisplay(dpy);

	if(_XCheckTypedWindowEvent(dpy, w, type, event, &prev))
		return True;
	if (prev)
		qe_serial = prev->qserial_num;
	_XEventsQueued(dpy, QueuedAfterReading);
	if (prev && prev->qserial_num != qe_serial)
		/* another thread has snatched this event */
		prev = NULL;

	if(_XCheckTypedWindowEvent(dpy, w, type, event, &prev))
		return True;
	if (prev)
		qe_serial = prev->qserial_num;
	_XFlush(dpy);
	if (prev && prev->qserial_num != qe_serial)
		/* another thread has snatched this event */
		prev = NULL;

	if(_XCheckTypedWindowEvent(dpy, w, type, event, &prev))
		return True;

	UnlockDisplay(dpy);
	return False;
}
