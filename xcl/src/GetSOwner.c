/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Window XGetSelectionOwner(register Display *dpy, Atom selection)
{
    XCBGetSelectionOwnerCookie c;
    XCBGetSelectionOwnerRep *r;
    Window ret;

    c = XCBGetSelectionOwner(XCBConnectionOfDisplay(dpy), XCLATOM(selection));
    r = XCBGetSelectionOwnerReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!r)
	return None;
    ret = r->owner.xid;
    free(r);
    return ret;
}
