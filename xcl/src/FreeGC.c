/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XFreeGC(register Display *dpy, GC gc)
{
    register _XExtension *ext;
    LockDisplay(dpy);
    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->free_GC) (*ext->free_GC)(dpy, gc, &ext->codes);
    UnlockDisplay(dpy);
    XCBFreeGC(XCBConnectionOfDisplay(dpy), XCLGCONTEXT(gc->gid));
    _XFreeExtData(gc->ext_data);
    Xfree(gc);
    return 1;
}
