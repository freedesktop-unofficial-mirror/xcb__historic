#include "xclint.h"

int XSetWindowBackground(register Display *dpy, Window w, unsigned long pixel)
{
    CARD32 values[] = { pixel };
    XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWBackPixel, values);
    return 1;
}

