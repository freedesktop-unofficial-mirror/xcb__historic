#include "xclint.h"

#define MAXIMTEXTREQ 255

int XDrawImageString(Display *dpy, const Drawable d, GC gc, int x, const int y, const char *string, int length)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    CHAR2B buf[MAXIMTEXTREQ];
    register CHAR2B *ptr;
    register int i;

    if(length <= 0)
	return 0;

    LockDisplay(dpy);
    FlushGC(dpy, gc);

    /* if it'll be used later, zero the high bytes of the buffer. */
    if(length > MAXIMTEXTREQ)
	for(i = MAXIMTEXTREQ, ptr = buf; i; --i)
	    (ptr++)->byte1 = 0;

    while(1)
    {
	i = (length > MAXIMTEXTREQ) ? MAXIMTEXTREQ : length;

	XCBImageText8(c, i, XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), x, y, string);

	length -= MAXIMTEXTREQ;
	if(length <= 0)
	    break;

	/* invariant: i == MAXIMTEXTREQ */
	for(ptr = buf; i; --i)
	    (ptr++)->byte2 = *string++;

	{
	    XCBQueryTextExtentsRep *r;
	    r = XCBQueryTextExtentsReply(c, XCBQueryTextExtents(c, XCLFONTABLE(gc->gid), MAXIMTEXTREQ, buf), 0);
	    if(!r)
		break;

	    x += cvtINT32toInt(r->overall_width);
	    free(r);
	}
    }
    UnlockDisplay(dpy);
    return 0;
}
