#include "xclint.h"

Window XCreateSimpleWindow(register Display *dpy, Window parent, int x, int y,
    unsigned int width, unsigned int height, unsigned int borderWidth,
    unsigned long border, unsigned long background)
{
    WINDOW w = XCBWINDOWNew(XCBConnectionOfDisplay(dpy));
    CARD32 values[] = { background, border };
    XCBCreateWindow(XCBConnectionOfDisplay(dpy), /* depth */ 0, w, XCLWINDOW(parent), x, y, width, height, borderWidth, /* class */ CopyFromParent, /* visual */ XCLVISUALID(CopyFromParent), CWBackPixel | CWBorderPixel, values);
    return w.xid;
}
