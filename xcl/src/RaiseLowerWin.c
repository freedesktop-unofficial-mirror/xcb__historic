#include "xclint.h"

int XRaiseWindow(Display *const dpy, const Window w)
{
	const static CARD32 values[] = { Above };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWStackMode, values);
	return 1;
}

int XLowerWindow(Display *const dpy, const Window w)
{
	const static CARD32 values[] = { Below };
	XCBConfigureWindow(XCBConnectionOfDisplay(dpy), XCLWINDOW(w), CWStackMode, values);
	return 1;
}
