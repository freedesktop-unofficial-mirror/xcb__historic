/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1990, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <string.h>

/* XXX: this implementation does no caching. */

Atom XInternAtom(Display *dpy, const char *name, const Bool onlyIfExists)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBInternAtomRep *r;
    Atom atom;

    if (!name)
	name = "";

    r = XCBInternAtomReply(c, XCBInternAtom(c, onlyIfExists, strlen(name), name), 0);
    if (!r)
	return None;
    atom = r->atom.xid;
    free(r);
    return atom;
}

Status XInternAtoms(Display *dpy, char **const names, const int count, const Bool onlyIfExists, Atom *const atoms_return)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBInternAtomCookie *cs;
    register int i;
    int ret = 1;

    cs = (XCBInternAtomCookie *) malloc(count * sizeof(XCBInternAtomCookie));
    if (!cs)
    {
	/* malloc failed: fall back to one InternAtom at a time */
	for (i = 0; i < count; ++i)
	    atoms_return[i] = XInternAtom(dpy, names[i], onlyIfExists);
	return 1;
    }

    for (i = 0; i < count; ++i)
	cs[i] = XCBInternAtom(c, onlyIfExists, strlen(names[i]), names[i]);

    for (i = 0; i < count; ++i) {
	XCBInternAtomRep *r;
	r = XCBInternAtomReply(c, cs[i], 0);
	if (!r) {
	    ret = 0; /* something failed... */
	    continue; /* ...but finish working anyway. */
	}
	atoms_return[i] = r->atom.xid;
	free(r);
    }

    free(cs);
    return ret;
}
