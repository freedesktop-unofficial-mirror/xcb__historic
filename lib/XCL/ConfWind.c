#include "xclint.h"

int XMoveResizeWindow(register Display *dpy, Window w, int x, int y, unsigned int width, unsigned int height)
{
    CARD32 values[] = { x, y, width, height };
    XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWX | CWY | CWWidth | CWHeight, values);
    return 1;
}
