/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

/* XXX: for once, XCL caches when Xlib doesn't. Hah! */

Bool XQueryExtension(Display *dpy, const char *name, int *major_opcode,
    int *first_event, int *first_error)
{
#if 1 /* FIXME: disabling extensions until XCL progresses further */
	return 0; /* extension not present */
#else
	XCBConnection *c = XCBConnectionOfDisplay(dpy);
	const XCBQueryExtensionRep *r = XCBQueryExtensionCached(c, name, 0);
	/* error check: Xlib doesn't check this */
	if(!r)
		return 0; /* extension not present */

	*major_opcode = r->major_opcode;
	*first_event = r->first_event;
	*first_error = r->first_error;
	/* must not free r: it's aliased from the cache. */
	return r->present;
#endif
}
