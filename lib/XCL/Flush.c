#include "xclint.h"

/* Flush all buffered output requests. */
/* NOTE: NOT necessary when calling any of the Xlib routines. */

void _XFlush(register Display *dpy)
{
    XCBFlush(XCBConnectionOfDisplay(dpy));
}

int XFlush(register Display *dpy)
{
    XCBFlush(XCBConnectionOfDisplay(dpy));
    return 1;
}
