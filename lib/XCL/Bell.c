#include "xclint.h"

int XBell(register Display *dpy, int percent)
{
    XCBBell(XCBConnectionOfDisplay(dpy), percent);
    return 1;
}

