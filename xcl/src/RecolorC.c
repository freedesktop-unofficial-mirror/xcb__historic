#include "xclint.h"

int XRecolorCursor(register Display *dpy, Cursor cursor, XColor *foreground, XColor *background)
{       
    XCBRecolorCursor(XCBConnectionOfDisplay(dpy), XCLCURSOR(cursor),
		    foreground->red,
		    foreground->green,
		    foreground->blue,
		    background->red,
		    background->green,
		    background->blue);
	
    return 1;
}

