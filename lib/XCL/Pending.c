#include "xclint.h"

/* Read in pending events if needed and return the number of queued events. */
int XEventsQueued(register Display *dpy, int mode)
{
    int ret_val;
    LockDisplay(dpy);
    if (dpy->qlen || (mode == QueuedAlready))
	ret_val = dpy->qlen;
    else
	ret_val = _XEventsQueued (dpy, mode);
    UnlockDisplay(dpy);
    return ret_val;
}

int XPending(Display *dpy)
{
    return XEventsQueued(dpy, QueuedAfterFlush);
}

int _XEventsQueued(register Display *dpy, int mode)
{
    fd_set fds;
    struct timeval tv = { 0, 0 };
    if(mode == QueuedAfterFlush)
    {
	_XFlush(dpy);
	if(dpy->qlen)
	    return(dpy->qlen);
    }
    if(XCBEventQueueIsEmpty(XCBConnectionOfDisplay(dpy)))
    {
	FD_ZERO(&fds);
	FD_SET(dpy->fd, &fds);
	if(select(dpy->fd + 1, &fds, 0, 0, &tv) < 1)
	    return(dpy->qlen);
    }
    _XReadEvents(dpy);
    return(dpy->qlen);
}
