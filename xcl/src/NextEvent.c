#include "xclint.h"
#include <assert.h>

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
	e = XCBWaitEvent(c);
	_XEnq(dpy, (xEvent *) e);
	while(!XCBEventQueueIsEmpty(c))
	{
		e = XCBWaitEvent(c);
		_XEnq(dpy, (xEvent *) e);
	}
}

/* _XEnq - Place event packets on the display's queue. note that no
 * squishing of move events in V11, since there is pointer motion hints... */
void _XEnq(register Display *dpy, register xEvent *event)
{
        register _XQEvent *qelt;

        if ((qelt = dpy->qfree)) {
                /* If dpy->qfree is non-NULL do this, else malloc a new one. */
                dpy->qfree = qelt->next;
        }
        else if ((qelt = (_XQEvent *) Xmalloc(sizeof(_XQEvent))) == NULL) {
                /* Malloc call failed! */
#if 0 /* not implemented yet */
                ESET(ENOMEM);
                _XIOError(dpy);
#else
		assert(qelt);
#endif
        }
        qelt->next = NULL;
        /* go call through display to find proper event reformatter */
        if ((*dpy->event_vec[event->u.u.type & 0177])(dpy, &qelt->event, event))
 {
		qelt->qserial_num = dpy->next_event_serial_num++;
		if (dpy->tail)
			dpy->tail->next = qelt;
		else
			dpy->head = qelt;
    
		dpy->tail = qelt;
		dpy->qlen++;
        } else {
		/* ignored, or stashed away for many-to-one compression */
		qelt->next = dpy->qfree;
		dpy->qfree = qelt;
        }
}

/* _XDeq - Remove event packet from the display's queue. */
/* prev: element before qelt */
/* qelt: element to be unlinked */
void _XDeq(register Display *dpy, register _XQEvent *prev, register _XQEvent *qelt)
{
    if (prev) {
        if ((prev->next = qelt->next) == NULL)
            dpy->tail = prev;
    } else {
        /* no prev, so removing first elt */
        if ((dpy->head = qelt->next) == NULL)
            dpy->tail = NULL;
    }
    qelt->qserial_num = 0;
    qelt->next = dpy->qfree;
    dpy->qfree = qelt;
    dpy->qlen--;
}
