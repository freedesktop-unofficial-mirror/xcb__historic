/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1987, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Cursor XCreateFontCursor(Display *dpy, unsigned int which)
{
    CURSOR c;

    /* the cursor font contains the shape glyph followed by the mask
     * glyph; so character position 0 contains a shape, 1 the mask for 0,
     * 2 a shape, etc.  <X11/cursorfont.h> contains hash define names
     * for all of these. */

    if (dpy->cursor_font == None) {
	dpy->cursor_font = XLoadFont (dpy, CURSORFONT);
	if (dpy->cursor_font == None) return None;
    }

    c = XCBCURSORNew(XCBConnectionOfDisplay(dpy));
    XCBCreateGlyphCursor(XCBConnectionOfDisplay(dpy), c, XCLFONT(dpy->cursor_font), XCLFONT(dpy->cursor_font), which, which + 1, /* fore */ 0, 0, 0, /* back */ 65535, 65535, 65535);
    return c.xid;
}
