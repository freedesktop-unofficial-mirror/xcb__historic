#include "xclint.h"

int XDeleteProperty(register Display *dpy, Window w, Atom property)
{
    XCBDeleteProperty(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), XCLATOM(property));
    return 1;
}
