#include "xclint.h"
#include <string.h>

/* XXX: this implementation does no caching. */

Atom XInternAtom(Display *dpy, const char *name, const Bool onlyIfExists)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    Atom atom;
    XCBInternAtomRep *r;

    if (!name)
	name = "";

    r = XCBInternAtomReply(c, XCBInternAtom(c, onlyIfExists, strlen(name), name), 0);
    if (!r)
	return None;
    atom = r->atom.xid;
    free(r);
    return (atom);
}

Status XInternAtoms(Display *dpy, char **const names, const int count, const Bool onlyIfExists, Atom *const atoms_return)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBInternAtomCookie *cs;
    register int i;
    int ret = 1;

    cs = (XCBInternAtomCookie *) malloc(count * sizeof(XCBInternAtomCookie));
    /* even if this memory allocation fails, ensure that every entry in
     * atoms_return is initialized. Xlib doesn't dynamically allocate
     * memory here, so it doesn't have this failure case. */
    if (!cs) {
	for (i = 0; i < count; ++i)
	    atoms_return[i] = None;
    /* now every entry in atoms_return has some sensible value, so we can
     * report the memory allocation failure. */
	return 0;
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
