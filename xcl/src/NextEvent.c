/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <assert.h>
#include <unistd.h>

/* Return next event in queue, or if none, flush output and wait for events. */
int XNextEvent(register Display *dpy, register XEvent *event)
{
	register _XQEvent *qelt;
	
	LockDisplay(dpy);
	if (dpy->head == NULL)
	    _XReadEvents(dpy);
	qelt = dpy->head;
	*event = qelt->event;
	_XDeq(dpy, NULL, qelt);
	UnlockDisplay(dpy);
	return 0;
}

/* _XReadEvents - Flush the output queue, then read as many events as
 * possible (but at least 1) and enqueue them. */
void _XReadEvents(Display *dpy)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBGenericEvent *e;

	if(XCBEventQueueIsEmpty(c))
		_XFlush(dpy);

	do {
		e = XCBWaitEvent(c);
		if(e->response_type == X_Error)
			_XError(dpy, (xError *) e);
		else
			_XEnq(dpy, (xEvent *) e);
		free(e);
	} while(!XCBEventQueueIsEmpty(c));
}

/* _XEnq - Place event packets on the display's queue. note that no
 * squishing of move events in V11, since there is pointer motion hints... */
void _XEnq(register Display *dpy, register xEvent *event)
{
        register _XQEvent *qelt;

        qelt = dpy->qfree;
        if(qelt)
                /* If dpy->qfree is non-NULL do this, else malloc a new one. */
                dpy->qfree = qelt->next;
	else
	        qelt = (_XQEvent *) Xmalloc(sizeof(_XQEvent));

#if 0 /* not implemented yet */
        if(!qelt)
                /* Malloc call failed! */
                ESET(ENOMEM);
                _XIOError(dpy);
        }
#else
	assert(qelt);
#endif

	/* invariant: qelt points to usable but uninitialized memory. */

        /* go call through display to find proper event reformatter */
        if(!(*dpy->event_vec[event->u.u.type & 0177])(dpy, &qelt->event, event))
	{
		/* reformatter told us not to enqueue this one after all.
		 * Put it back on the free list. */
		qelt->next = dpy->qfree;
		dpy->qfree = qelt;
		return;
        }

	/* invariant: qelt->event is initialized but nothing else is. */
	qelt->qserial_num = dpy->next_event_serial_num++;

	/* list method: append at end */
	if(dpy->tail)
		dpy->tail->next = qelt;
	else
		dpy->head = qelt;

	dpy->tail = qelt;
        qelt->next = NULL;

	dpy->qlen++;
}

/* _XDeq - Remove event packet from the display's queue. */
/* prev: element before qelt */
/* qelt: element to be unlinked */
void _XDeq(register Display *dpy, register _XQEvent *prev, register _XQEvent *qelt)
{
    if(prev)
        prev->next = qelt->next;
    else
	dpy->head = qelt->next;

    if(!qelt->next)
	dpy->tail = prev;

    qelt->qserial_num = 0;
    qelt->next = dpy->qfree;
    dpy->qfree = qelt;
    dpy->qlen--;
}
