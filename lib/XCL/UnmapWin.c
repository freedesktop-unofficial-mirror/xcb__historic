#include "xclint.h"

int XUnmapWindow(register Display *dpy, Window w)
{
    XCBUnmapWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w));
    return 1;
}

