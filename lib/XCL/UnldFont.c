#include "xclint.h"

int XUnloadFont(Display *dpy, Font font)
{
	XCBCloseFont(XCBConnectionOfDisplay(dpy), XCLFONT(font));
	return 1;
}

