#include "xclint.h"

int XResizeWindow(register Display *dpy, Window w, unsigned int width, unsigned int height)
{
    CARD32 values[] = { width, height };
    XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWWidth | CWHeight, values);
    return 1;
}
