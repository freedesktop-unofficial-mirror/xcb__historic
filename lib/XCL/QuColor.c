#include "xclint.h"
#include <assert.h>

int XQueryColor(Display *dpy, Colormap cmap, XColor *def)
{
    return XQueryColors(dpy, cmap, def, 1);
}

int XQueryColors(Display *dpy, Colormap cmap, XColor *const defs, const int ncolors)
{
    register int i;
    RGB *colors;
    XCBQueryColorsCookie c;
    XCBQueryColorsRep *rep;

    {
        CARD32 *pixels;
        pixels = malloc(sizeof(CARD32) * ncolors);
        if (!pixels)
	    return 1; /* on error, leave defaults alone */

        for(i = 0; i < ncolors; ++i)
	    pixels[i] = defs[i].pixel;
    
        c = XCBQueryColors(XCBConnectionOfDisplay(dpy), XCLCOLORMAP(cmap), ncolors, pixels);
        free(pixels);
    }

    rep = XCBQueryColorsReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!rep)
	return 1; /* on error, leave defaults alone */

    colors = XCBQueryColorscolors(rep);
    
    assert(rep->colors_len == ncolors);

    for(i = 0; i < rep->colors_len; ++i)
    {
	defs[i].red = colors[i].red;
	defs[i].green = colors[i].green;
	defs[i].blue = colors[i].blue;
	defs[i].flags = DoRed | DoGreen | DoBlue;
    }
   
    free(rep);
    return 1;
}
