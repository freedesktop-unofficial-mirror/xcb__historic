#include "xclint.h"

/*
 * In order to avoid all images requiring _XEventToWire, we install the
 * event converter here if it has never been installed.
 */
Status XSendEvent(register Display *dpy, Window window, Bool propagate, long event_mask, XEvent *event)
{
    char ev[32];
    register Status (**fp)();
    Status status;

    /* call through display to find proper conversion routine */

    LockDisplay (dpy);
    fp = &dpy->wire_vec[event->type & 0177];
    if (*fp == NULL) *fp = _XEventToWire;
    status = (**fp)(dpy, event, (xEvent *) ev);
    UnlockDisplay(dpy);

    if (status) {
	WINDOW w = { window };
	XCBSendEvent(XCBConnectionOfDisplay(dpy), propagate, w, event_mask, ev);
    }

    return status;
}
