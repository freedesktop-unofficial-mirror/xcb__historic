#include "xclint.h"

int XMoveWindow(Display *const dpy, const Window w, const int x, const int y)
{
	CARD32 values[] = { x, y };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWX | CWY, values);
	return 1;
}
