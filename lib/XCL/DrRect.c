#include "xclint.h"

int XDrawRectangle(register Display *dpy, Drawable drawable, GC gc, int x, int y, unsigned int width, unsigned int height)
{
    RECTANGLE r = { x, y, width, height };

    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBPolyRectangle(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(drawable), XCLGCONTEXT(gc->gid), 1, &r);
    UnlockDisplay(dpy);
    return 1;
}
