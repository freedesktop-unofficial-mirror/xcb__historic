/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

/* Synchronize with errors and events, optionally discarding pending events */

int XSync(register Display *dpy, Bool discard)
{
    LockDisplay(dpy);
    XCBSync(XCBConnectionOfDisplay(dpy), 0);
	
    if (discard && dpy->head)
    {
       _XQEvent *qelt;

       for (qelt = dpy->head; qelt; qelt = qelt->next)
	   qelt->qserial_num = 0;

       ((_XQEvent *)dpy->tail)->next = dpy->qfree;
       dpy->qfree = (_XQEvent *)dpy->head;
       dpy->head = dpy->tail = NULL;
       dpy->qlen = 0;
    }
    UnlockDisplay(dpy);
    return 1;
}

