#include "xclint.h"

int XCopyArea(register Display *dpy,
    Drawable src_drawable, Drawable dst_drawable, GC gc,
    int src_x, int src_y, unsigned int width, unsigned int height,
    int dst_x, int dst_y)
{
    LockDisplay(dpy);
    FlushGC(dpy, gc);
    XCBCopyArea(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(src_drawable), XCLDRAWABLE(dst_drawable), XCLGCONTEXT(gc->gid), src_x, src_y, dst_x, dst_y, width, height);
    UnlockDisplay(dpy);
    return 1;
}
