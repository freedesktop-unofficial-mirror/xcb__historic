#include "xclint.h"

int XClearArea(register Display *dpy, Window w, int x, int y, unsigned int width, unsigned int height, Bool exposures)
{
    XCBClearArea(XCBConnectionOfDisplay(dpy), exposures, XCLWINDOW(w), x, y, width, height);
    return 1;
}

