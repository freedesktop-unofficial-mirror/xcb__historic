#include "xclint.h"

int XDrawImageString(register Display *dpy, Drawable d, GC gc, int x, int y, const char *string, int length)
{
    char *CharacterOffset = (char *)string;
    int FirstTimeThrough = True;
    int lastX = 0;

    LockDisplay(dpy);
    FlushGC(dpy, gc);

    while (length > 0) 
    {
	int Unit;

	if (length > 255) Unit = 255;
	else Unit = length;

   	if (FirstTimeThrough)
	{
	    FirstTimeThrough = False;
        }
	else
	{
	    char buf[512];
	    char *ptr, *str;
	    XCBQueryTextExtentsCookie c;
	    XCBQueryTextExtentsRep *r;
	    int i;

	    str = CharacterOffset - 255;
	    for(ptr = buf, i = 255; --i >= 0; )
	    {
		*ptr++ = 0;
		*ptr++ = *str++;
	    }

	    c = XCBQueryTextExtents(XCBConnectionOfDisplay(dpy), XCLFONTABLE(gc->gid), 255, (CHAR2B *) buf);
	    r = XCBQueryTextExtentsReply(XCBConnectionOfDisplay(dpy), c, 0);
	    if(!r)
		break;

	    x = lastX + cvtINT32toInt(r->overall_width);
	    free(r);
	}

	XCBImageText8(XCBConnectionOfDisplay(dpy), Unit, XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), x, y, CharacterOffset);

	lastX = x;
        CharacterOffset += Unit;
	length -= Unit;
    }
    UnlockDisplay(dpy);
    return 0;
}
