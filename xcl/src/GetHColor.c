#include "xclint.h"

Status XAllocColor(register Display *dpy, Colormap cmap, XColor *def)
{
    XCBAllocColorCookie c;
    XCBAllocColorRep *r;

    c = XCBAllocColor(XCBConnectionOfDisplay(dpy), XCLCOLORMAP(cmap), def->red, def->green, def->blue);
    r = XCBAllocColorReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!r)
	return 0;

    def->red = r->red;
    def->green = r->green;
    def->blue = r->blue;
    def->pixel = r->pixel;
    free(r);
    return 1;
}
