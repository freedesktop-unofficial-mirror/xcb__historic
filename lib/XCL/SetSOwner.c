#include "xclint.h"

int XSetSelectionOwner(register Display *dpy, Atom selection, Window owner, Time time)
{
    XCBSetSelectionOwner(XCBConnectionOfDisplay(dpy), XCLWINDOW(owner), XCLATOM(selection), XCLTIMESTAMP(time));
    return 1;
}
