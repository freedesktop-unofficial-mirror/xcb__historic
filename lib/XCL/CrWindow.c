/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Window XCreateSimpleWindow(Display *dpy, Window parent, int x, int y,
    unsigned int width, unsigned int height, unsigned int borderWidth,
    unsigned long border, unsigned long background)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    WINDOW w = XCBWINDOWNew(c);
    CARD32 values[] = { background, border };
    XCBCreateWindow(c, /* depth */ 0, w, XCLWINDOW(parent), x, y, width, height, borderWidth, /* class */ CopyFromParent, XCLVISUALID(CopyFromParent), CWBackPixel | CWBorderPixel, values);
    return w.xid;
}

static void _XProcessWindowAttributes(unsigned long valuemask, XSetWindowAttributes *attributes, CARD32 *value)
{
    if (valuemask & CWBackPixmap)
	*value++ = attributes->background_pixmap;
	
    if (valuemask & CWBackPixel)
    	*value++ = attributes->background_pixel;

    if (valuemask & CWBorderPixmap)
    	*value++ = attributes->border_pixmap;

    if (valuemask & CWBorderPixel)
    	*value++ = attributes->border_pixel;

    if (valuemask & CWBitGravity)
    	*value++ = attributes->bit_gravity;

    if (valuemask & CWWinGravity)
	*value++ = attributes->win_gravity;

    if (valuemask & CWBackingStore)
        *value++ = attributes->backing_store;
    
    if (valuemask & CWBackingPlanes)
	*value++ = attributes->backing_planes;

    if (valuemask & CWBackingPixel)
    	*value++ = attributes->backing_pixel;

    if (valuemask & CWOverrideRedirect)
    	*value++ = attributes->override_redirect;

    if (valuemask & CWSaveUnder)
    	*value++ = attributes->save_under;

    if (valuemask & CWEventMask)
	*value++ = attributes->event_mask;

    if (valuemask & CWDontPropagate)
	*value++ = attributes->do_not_propagate_mask;

    if (valuemask & CWColormap)
	*value++ = attributes->colormap;

    if (valuemask & CWCursor)
	*value++ = attributes->cursor;
}

#define AllMaskBits (CWBackPixmap|CWBackPixel|CWBorderPixmap|\
		     CWBorderPixel|CWBitGravity|CWWinGravity|\
		     CWBackingStore|CWBackingPlanes|CWBackingPixel|\
		     CWOverrideRedirect|CWSaveUnder|CWEventMask|\
		     CWDontPropagate|CWColormap|CWCursor)

Window XCreateWindow(dpy, parent, x, y, width, height, 
                borderWidth, depth, class, visual, valuemask, attributes)
    Display *dpy;
    Window parent;
    int x, y;
    unsigned int width, height, borderWidth;
    int depth;
    unsigned int class;
    Visual *visual;
    unsigned long valuemask;
    XSetWindowAttributes *attributes;
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    WINDOW w = XCBWINDOWNew(c);
    VisualID v;
    CARD32 values[32];

    if (visual == CopyFromParent)
	v = CopyFromParent;
    else
	v = visual->visualid;
    valuemask &= AllMaskBits;
    _XProcessWindowAttributes(valuemask, attributes, values);

    XCBCreateWindow(c, depth, w, XCLWINDOW(parent), x, y, width, height, borderWidth, class, XCLVISUALID(v), valuemask, values);
    return w.xid;
}
