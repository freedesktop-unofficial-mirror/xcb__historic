/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Font XLoadFont(register Display *dpy, const char *name)
{
    FONT f = XCBFONTNew(XCBConnectionOfDisplay(dpy));

#if 0 /* locales disabled */
    if (_XF86LoadQueryLocaleFont(dpy, name, (XFontStruct **)0, &fid))
	return fid;
#endif

    XCBOpenFont(XCBConnectionOfDisplay(dpy), f, name ? strlen(name) : 0, name);
    return f.xid;
}
