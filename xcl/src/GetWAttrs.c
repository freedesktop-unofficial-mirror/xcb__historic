/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

Status XGetWindowAttributes(register Display *dpy, Window window, XWindowAttributes *attr)
{
    XCBGetGeometryCookie gc;
    XCBGetGeometryRep *gr;
    XCBGetWindowAttributesCookie ac;
    XCBGetWindowAttributesRep *ar;
    register int i;
    register Screen *sp;

    gc = XCBGetGeometry(XCBConnectionOfDisplay(dpy), XCLDRAWABLE(window));
    ac = XCBGetWindowAttributes(XCBConnectionOfDisplay(dpy), XCLWINDOW(window));
    gr = XCBGetGeometryReply(XCBConnectionOfDisplay(dpy), gc, 0);
    ar = XCBGetWindowAttributesReply(XCBConnectionOfDisplay(dpy), ac, 0);
    /* Xlib kills BadDrawable errors from GetGeometry, but I can't be arsed. */
    if (!gr || !ar)
	goto error;

    attr->depth = gr->depth;
    attr->root = gr->root.xid;
    attr->x = cvtINT16toInt (gr->x);
    attr->y = cvtINT16toInt (gr->y);
    attr->width = gr->width;
    attr->height = gr->height;
    attr->border_width = gr->border_width;

    attr->backing_store = ar->backing_store;
    attr->visual = _XVIDtoVisual (dpy, ar->visual.id);
    attr->class = ar->_class;
    attr->bit_gravity = ar->bit_gravity;
    attr->win_gravity = ar->win_gravity;
    attr->backing_planes = ar->backing_planes;
    attr->backing_pixel = ar->backing_pixel;
    attr->save_under = ar->save_under;
    attr->map_installed = ar->map_is_installed;
    attr->map_state = ar->map_state;
    attr->override_redirect = ar->override_redirect;
    attr->colormap = ar->colormap.xid;
    attr->all_event_masks = ar->all_event_masks;
    attr->your_event_mask = ar->your_event_mask;
    attr->do_not_propagate_mask = ar->do_not_propagate_mask;

    /* find correct screen so that applications find it easier.... */
    for (i = dpy->nscreens, sp = dpy->screens; i; --i, ++sp)
	if (sp->root == attr->root) {
	    attr->screen = sp;
	    break;
	}

    free(gr);
    free(ar);
    return 1; /* success */

error:
    free(gr);
    free(ar);
    return 0; /* failure */
}
