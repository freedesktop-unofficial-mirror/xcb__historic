#include "xclint.h"

/* FIXME: PolyText8 doesn't work, somehow. Make it work. */
int XDrawString(register Display *dpy, Drawable drawable, GC gc, int x, int y, const char *string, int length)
{
#if 1
	return XDrawImageString(dpy, drawable, gc, x, y, string, length);
#else
    int Datalength, nbytes;
    unsigned char *buf, *bufp;
    
    if (length <= 0)
       return 0;

    Datalength = 2 * ((length + 253) / 254) + length;

    bufp = buf = malloc(Datalength);
    /* Xlib doesn't malloc here, and so doesn't have any failure cases.
     * Choices: abort(), or return same value as above error case (0). */
    if (!buf)
        return 0;

    while (length > 0)
    {
	nbytes = (length > 254) ? 254 : length;
            
	*bufp = (unsigned char) nbytes;
	++bufp;
	*bufp = 0;
	++bufp;
            
	memcpy (bufp, string, nbytes);
	length -= nbytes;
	string += nbytes;
	bufp += nbytes;
    }

    XCBPolyText8(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(drawable), XCLGCONTEXT(gc->gid), x, y, Datalength, buf);

    free(buf);
    return 0;
#endif
}
