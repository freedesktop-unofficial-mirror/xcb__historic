#include "xclint.h"

int XSelectInput(Display *dpy, Window w, long mask)
{
    CARD32 values[1] = { mask };
    XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), XCBCWEventMask, values);
    return 1;
}

