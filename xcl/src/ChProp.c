/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

/* format: 8, 16, or 32 */
/* mode: PropModeReplace, PropModePrepend, PropModeAppend */
int XChangeProperty(register Display *dpy, Window w, Atom prop, Atom type,
    int format, int mode, const unsigned char *data, int nelements)
{
    /* error check the input */
    if (nelements < 0 || (format != 8 && format != 16 && format != 32)) {
	nelements = 0;
	format = 0;
    }

    XCBChangeProperty(XCBConnectionOfDisplay(dpy), mode, XCLWINDOW(w), XCLATOM(prop), XCLATOM(type), format, nelements, data);
    return 1;
}
