#include "xclint.h"

int XDefineCursor(register Display *dpy, Window w, Cursor cursor)
{
    CARD32 values[] = { cursor };
    XCBChangeWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWCursor, values);
    return 1;
}

