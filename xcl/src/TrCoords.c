#include "xclint.h"

Bool XTranslateCoordinates(Display *dpy, Window src_win, Window dest_win, int src_x, int src_y, int *dst_x, int *dst_y, Window *child)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBTranslateCoordinatesRep *r;
	Bool ret;

	r = XCBTranslateCoordinatesReply(c, XCBTranslateCoordinates(c, XCLWINDOW(src_win), XCLWINDOW(dest_win), src_x, src_y), 0);
	if(!r)
		return False;

	*child = r->child.xid;
	*dst_x = cvtINT16toInt(r->dst_x);
	*dst_y = cvtINT16toInt(r->dst_y);
	ret = r->same_screen;
	free(r);
	return ret;
}
