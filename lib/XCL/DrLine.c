#include "xclint.h"

int XDrawLine(register Display *dpy, Drawable drawable, GC gc, int x1, int y1, int x2, int y2)
{
    SEGMENT s = { x1, y1, x2, y2 };

    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBPolySegment(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(drawable), XCLGCONTEXT(gc->gid), 1, &s);
    UnlockDisplay(dpy);
    return 1;
}
