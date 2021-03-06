/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1985, 1990, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

#if 0 /* not needed yet */
extern void _XFreeDisplayStructure();

/* ConnDis.c */
extern int _XDisconnectDisplay();
#endif

/* XCloseDisplay - XSync the connection to the X Server, close the connection,
 * and free all associated storage.  Extension close procs should only free
 * memory and must be careful about the types of requests they generate. */
int XCloseDisplay(register Display *dpy)
{
	register _XExtension *ext;
	register int i;

	if (!(dpy->flags & XlibDisplayClosing))
	{
	    dpy->flags |= XlibDisplayClosing;
	    for (i = 0; i < dpy->nscreens; i++) {
		    register Screen *sp = &dpy->screens[i];
		    XFreeGC (dpy, sp->default_gc);
	    }
	    if (dpy->cursor_font != None) {
		XUnloadFont (dpy, dpy->cursor_font);
	    }
	    XSync(dpy, 1);  /* throw away pending events, catch errors */
	    /* call out to any extensions interested */
	    for (ext = dpy->ext_procs; ext; ext = ext->next) {
		if (ext->close_display)
		    (*ext->close_display)(dpy, &ext->codes);
	    }
	    /* if the closes generated more protocol, sync them up */
	    if (dpy->request != dpy->last_request_read)
		XSync(dpy, 1);
	}
#if 0 /* not needed yet */
	_XDisconnectDisplay(dpy->trans_conn);
	_XFreeDisplayStructure (dpy);
#endif
	return 0;
}
