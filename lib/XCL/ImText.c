#include "xclint.h"

/* XXX: Xlib returns 0 in all cases. This returns non-zero (success) in most
 * cases and 0 (failure) in some cases. */
int XDrawImageString(register Display *dpy, Drawable d, GC gc, int x, int y, const char *p, int length)
{
    char *buf, *bufp;
    int qty;

    /* XXX: Xlib might produce ChangeGC requests in cases where this won't. */
    if (length <= 0)
	return 1; /* success */

    qty = (length + 253) / 254;
    bufp = buf = (char *) malloc(length + qty * 2);
    if (!buf)
	return 0; /* failure */
    while (length > 254) {
	*bufp++ = 254;
	*bufp++ = 0; /* delta */
	memcpy(bufp, p, 254);
	length -= 254;
	bufp += 254;
	p += 254;
    }
    *bufp++ = length;
    *bufp++ = 0; /* delta */
    memcpy(bufp, p, length);

    LockDisplay(dpy);
    FlushGC(dpy, gc);

    XCBPolyText8(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), x, y, qty, buf);
    free(buf);
    UnlockDisplay(dpy);
    return 1; /* success */
}
