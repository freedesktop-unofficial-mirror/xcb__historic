/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

/* can only call when display is locked. */
void _XSetClipRectangles(Display *dpy, GC gc, int clip_x_origin, int clip_y_origin, XRectangle *rectangles, int n, int ordering)
{
	unsigned long dirty;
	register _XExtension *ext;
	XCBSetClipRectangles(XCBConnectionOfDisplay(dpy), ordering, XCLGCONTEXT(gc->gid), clip_x_origin, clip_y_origin, n, (RECTANGLE *) rectangles);

	gc->values.clip_x_origin = clip_x_origin;
	gc->values.clip_y_origin = clip_y_origin;
	gc->rects = 1;
	dirty = gc->dirty & ~(GCClipMask | GCClipXOrigin | GCClipYOrigin);
	gc->dirty = GCClipMask | GCClipXOrigin | GCClipYOrigin;
	/* call out to any extensions interested */
	for (ext = dpy->ext_procs; ext; ext = ext->next)
		if (ext->flush_GC) (*ext->flush_GC)(dpy, gc, &ext->codes);
	gc->dirty = dirty;
}

int XSetClipRectangles(Display *dpy, GC gc, int clip_x_origin, int clip_y_origin, XRectangle *rectangles, int n, int ordering)
{
	LockDisplay(dpy);
	_XSetClipRectangles(dpy, gc, clip_x_origin, clip_y_origin, rectangles, n, ordering);
	UnlockDisplay(dpy);
	return 1;
}
