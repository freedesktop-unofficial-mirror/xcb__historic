#include <stdio.h>
#include "xclint.h"

Status XParseColor(register Display *dpy, Colormap cmap, const char *spec, XColor *def)
{
	register int n, i;
	int r, g, b;
	char c;

        if (!spec) return(0);
	n = strlen (spec);
	if (*spec == '#') {
	    /*
	     * RGB
	     */
	    spec++;
	    n--;
	    if (n != 3 && n != 6 && n != 9 && n != 12)
		return (0);
	    n /= 3;
	    g = b = 0;
	    do {
		r = g;
		g = b;
		b = 0;
		for (i = n; --i >= 0; ) {
		    c = *spec++;
		    b <<= 4;
		    if (c >= '0' && c <= '9')
			b |= c - '0';
		    else if (c >= 'A' && c <= 'F')
			b |= c - ('A' - 10);
		    else if (c >= 'a' && c <= 'f')
			b |= c - ('a' - 10);
		    else return (0);
		}
	    } while (*spec != '\0');
	    n <<= 2;
	    n = 16 - n;
	    def->red = r << n;
	    def->green = g << n;
	    def->blue = b << n;
	    def->flags = DoRed | DoGreen | DoBlue;
	    return (1);
	}

	{
	    COLORMAP cm = { cmap };
	    XCBLookupColorCookie c;
	    XCBLookupColorRep *r;
	    
	    c = XCBLookupColor(XCBConnectionOfDisplay(dpy), cm, strlen(spec), spec);
	    r = XCBLookupColorReply(XCBConnectionOfDisplay(dpy), c, 0);
	    
	    if (!r)
	    {
		return 0;
	    }
	    	    
	    def->red = r->exact_red;
	    def->green = r->exact_green;
	    def->blue = r->exact_blue;
	    def->flags = DoRed | DoGreen | DoBlue;
	    return (1);
	}
}
