/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Window XGetSelectionOwner(Display *dpy, Atom selection)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetSelectionOwnerRep *r;
    Window ret;

    r = XCBGetSelectionOwnerReply(c, XCBGetSelectionOwner(c, XCLATOM(selection)), 0);
    if (!r)
	return None;
    ret = r->owner.xid;
    free(r);
    return ret;
}
