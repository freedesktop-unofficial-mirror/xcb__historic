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
