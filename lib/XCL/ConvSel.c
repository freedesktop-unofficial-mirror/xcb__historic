#include "xclint.h"

int XConvertSelection(register Display *dpy, Atom selection, Atom target, Atom property, Window requestor, Time time)
{
    XCBConvertSelection(XCBConnectionOfDisplay(dpy), XCLWINDOW(requestor), XCLATOM(selection), XCLATOM(target), XCLATOM(property), XCLTIMESTAMP(time));
    return 1;
}
