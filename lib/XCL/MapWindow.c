#include "xclint.h"

int XMapWindow(Display *dpy, Window window)
{
    XCBMapWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(window));
    return 1;
}
