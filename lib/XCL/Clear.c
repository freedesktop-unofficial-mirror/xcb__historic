#include "xclint.h"

int XClearWindow(register Display *dpy, Window w)
{
    /* (x, y, width, height) = 0 means "clear the entire window" */
    XCBClearArea(XCBConnectionOfDisplay(dpy), /*exposures*/ 0, XCLWINDOW(w), 0, 0, 0, 0);
    return 1;
}

