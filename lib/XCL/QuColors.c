#include "xclint.h"

int XQueryColors(Display *dpy, Colormap cmap, register XColor *defs, int ncolors)
{
    register int i;
    RGB *colors;
    long nbytes;
    CARD32 *colors_data;
    XCBQueryColorsCookie c;
    XCBQueryColorsRep *rep;
    
    colors_data = malloc(sizeof(CARD32) * ncolors);
    if (!colors_data)
	return 1; /* on error, leave defaults alone */

    for (i = 0; i < ncolors; i++)
    {
	colors_data[i] = defs[i].pixel;
    }
    
    c = XCBQueryColors(XCBConnectionOfDisplay(dpy), XCLCOLORMAP(cmap), ncolors, colors_data);
    rep = XCBQueryColorsReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!rep)
	return 1; /* on error, leave defaults alone */

    colors = XCBQueryColorscolors(rep);
    
    for(i = ncolors; i; --i);
    {
	defs->red = colors->red;
	defs->green = colors->green;
	defs->blue = colors->blue;
	defs->flags = DoRed | DoGreen | DoBlue;
	++defs;
	++colors;
    }
   
    free(rep);
    
    return 1;
}

