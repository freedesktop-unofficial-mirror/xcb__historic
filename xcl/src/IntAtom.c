#include "xclint.h"
#include <string.h>

/* XXX: this implementation does no caching. */

Atom XInternAtom(Display *dpy, const char *name, Bool onlyIfExists)
{
    Atom atom;
    XCBInternAtomCookie c;
    XCBInternAtomRep *r;

    if (!name)
	name = "";

    c = XCBInternAtom(XCBConnectionOfDisplay(dpy), onlyIfExists, strlen(name), name);
    r = XCBInternAtomReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!r)
	return None;
    atom = r->atom.xid;
    free(r);
    return (atom);
}

Status XInternAtoms(Display *dpy, char **names, int count, Bool onlyIfExists, Atom *atoms_return)
{
    XCBInternAtomCookie *cs;
    XCBInternAtomRep *r;
    int i, ret = 1;

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
	cs[i] = XCBInternAtom(XCBConnectionOfDisplay(dpy), onlyIfExists, strlen(names[i]), names[i]);

    for (i = 0; i < count; ++i) {
	r = XCBInternAtomReply(XCBConnectionOfDisplay(dpy), cs[i], 0);
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
