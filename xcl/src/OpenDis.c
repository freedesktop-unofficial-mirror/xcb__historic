/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1985, 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xatom.h>
#include <stdio.h>
#include <unistd.h>

#ifdef XKB
#include "XKBlib.h"
#endif /* XKB */

#ifdef X_NOT_POSIX
#define Size_t unsigned int
#else
#define Size_t size_t
#endif

#define bignamelen (sizeof(XBigReqExtensionName) - 1)

void _XFreeDisplayStructure(register Display *dpy);

typedef struct {
    unsigned long seq;
    int opcode;
} _XBigReqState;

#ifdef WIN32
int *_Xdebug_p = &_Xdebug;
#endif

#ifdef XTHREADS
#include "locking.h"
int  (*_XInitDisplayLock_fn)(Display *dpy) = NULL;
void (*_XFreeDisplayLock_fn)(Display *dpy) = NULL;

#define InitDisplayLock(d)	(_XInitDisplayLock_fn ? (*_XInitDisplayLock_fn)(d) : Success)
#define FreeDisplayLock(d)	if (_XFreeDisplayLock_fn) (*_XFreeDisplayLock_fn)(d)
#else
#define InitDisplayLock(dis) Success
#define FreeDisplayLock(dis)
#endif /* XTHREADS */

static Display _default_display;
static void _XInitDefaultDisplay()
{
	static unsigned done = 0;
	register int i;
	if(done)
		return;
	++done;

	/* Set the default error handlers.  This allows the global variables
	 * to default to NULL for use with shared libraries. */
	if (_XErrorFunction == NULL) (void) XSetErrorHandler (NULL);
	if (_XIOErrorFunction == NULL) (void) XSetIOErrorHandler (NULL);

	/* Initialize as much of the display structure as we can. */
	_default_display.lock_meaning		= NoSymbol;
	_default_display.event_vec[X_Error]	= _XUnknownWireEvent;
	_default_display.event_vec[X_Reply]	= _XUnknownWireEvent;
	_default_display.wire_vec[X_Error]	= _XUnknownNativeEvent;
	_default_display.wire_vec[X_Reply]	= _XUnknownNativeEvent;
	for (i = KeyPress; i < LASTEvent; i++) {
	    _default_display.event_vec[i] 	= _XWireToEvent;
	}
	for (i = LASTEvent; i < 128; i++) {
	    _default_display.event_vec[i] 	= _XUnknownWireEvent;
	    _default_display.wire_vec[i] 	= _XUnknownNativeEvent;
	}
	_default_display.next_event_serial_num = 1;

	_default_display.vnumber = X_PROTOCOL;
}

static int _XInitPixmapFormats(register Display *dpy)
{
	int i;
	register ScreenFormat *fmtdst;
	register FORMAT *fmtsrc;

	/* Now iterate down setup information... */
	fmtdst = (ScreenFormat *) Xmalloc(dpy->nformats * sizeof(ScreenFormat));
	if(!fmtdst)
		return 0;
	dpy->pixmap_format = fmtdst;
	fmtsrc = XCBConnectionOfDisplay(dpy)->pixmapFormats;

	/* First decode the Z axis Screen format information. */
	for(i = dpy->nformats; i; --i, ++fmtsrc, ++fmtdst)
	{
		fmtdst->depth = fmtsrc->depth;
		fmtdst->bits_per_pixel = fmtsrc->bits_per_pixel;
		fmtdst->scanline_pad = fmtsrc->scanline_pad;
		fmtdst->ext_data = NULL;
	}
	return 1;
}

static int _XInitVisuals(Depth *dpdst, register VISUALTYPE *vpsrc)
{
	int i;
	Visual *vpdst;

	if(dpdst->nvisuals <= 0)
	{
		dpdst->visuals = (Visual *) NULL;
		return 1;
	}

	vpdst = (Visual *) Xmalloc(dpdst->nvisuals * sizeof(Visual));
	if(!vpdst)
		return 0;
	dpdst->visuals = vpdst;

	for(i = dpdst->nvisuals; i; --i, ++vpsrc, ++vpdst)
	{
		vpdst->visualid		= vpsrc->visual_id.id;
		vpdst->class		= vpsrc->class;
		vpdst->bits_per_rgb	= vpsrc->bits_per_rgb_value;
		vpdst->map_entries	= vpsrc->colormap_entries;
		vpdst->red_mask		= vpsrc->red_mask;
		vpdst->green_mask	= vpsrc->green_mask;
		vpdst->blue_mask	= vpsrc->blue_mask;
		vpdst->ext_data		= NULL;
	}
	return 1;
}

static int _XInitDepths(Screen *spdst, register XCBDepth *dpsrc)
{
	int i;
	register Depth *dpdst;

	/* lets set up the depth structures. */
	dpdst = (Depth *) Xmalloc(spdst->ndepths * sizeof(Depth));
	if(!dpdst)
		return 0;
	spdst->depths = dpdst;

	/* for all depths on this screen. */
	for(i = spdst->ndepths; i; --i, ++dpsrc, ++dpdst)
	{
		dpdst->depth		= dpsrc->data->depth;
		dpdst->nvisuals		= dpsrc->data->visuals_len;

		if(!_XInitVisuals(dpdst, dpsrc->visuals))
			return 0;
	}
	return 1;
}

static int _XInitScreens(register Display *dpy)
{
	int i;
	register Screen *spdst;
	register XCBScreen *spsrc;
	XGCValues values;

	/* next the Screen structures. */
	spdst = (Screen *) Xmalloc(dpy->nscreens * sizeof(Screen));
	if(!spdst)
		return 0;
	dpy->screens = spdst;
	spsrc = XCBConnectionOfDisplay(dpy)->roots;

	/* Now go deal with each screen structure. */
	for(i = dpy->nscreens; i; --i, ++spsrc, ++spdst)
	{
		spdst->display		= dpy;
		spdst->root 		= spsrc->data->root.xid;
		spdst->cmap 		= spsrc->data->default_colormap.xid;
		spdst->white_pixel	= spsrc->data->white_pixel;
		values.background	= spdst->white_pixel;
		spdst->black_pixel	= spsrc->data->black_pixel;
		values.foreground	= spdst->black_pixel;
		spdst->root_input_mask	= spsrc->data->current_input_masks;
		spdst->width		= spsrc->data->width_in_pixels;
		spdst->height		= spsrc->data->height_in_pixels;
		spdst->mwidth		= spsrc->data->width_in_millimeters;
		spdst->mheight		= spsrc->data->height_in_millimeters;
		spdst->min_maps		= spsrc->data->min_installed_maps;
		spdst->max_maps		= spsrc->data->max_installed_maps;
		spdst->backing_store	= spsrc->data->backing_stores;
		spdst->save_unders	= spsrc->data->save_unders;
		spdst->root_depth	= spsrc->data->root_depth;
		spdst->ndepths		= spsrc->data->allowed_depths_len;
		spdst->ext_data		= NULL;

		if(!_XInitDepths(spdst, spsrc->depths))
			return 0;

		spdst->root_visual = _XVIDtoVisual(dpy, spsrc->data->root_visual.id);

		/* Set up other stuff clients are always going to use. */
		spdst->default_gc = XCreateGC(dpy, spdst->root, GCForeground|GCBackground, &values);
		if(!spdst->default_gc)
			return 0;
	}
	return 1;
}

/* Connects to a server, creates a Display object and returns a pointer to
 * the newly created Display back to the caller. */
Display *XOpenDisplay (register const char *display)
{
	register Display *dpy = 0;	/* New Display object being created. */
	XCBConnection *c = 0;		/* underlying XCB connection */
	char *display_name;		/* pointer to display name */

	_XInitDefaultDisplay();

	/*
	 * If the display specifier string supplied as an argument to this 
	 * routine is NULL or a pointer to NULL, read the DISPLAY variable.
	 */
	if (display == NULL || *display == '\0') {
		if ((display_name = getenv("DISPLAY")) == NULL) {
			/* Oops! No DISPLAY environment variable - error. */
			return(NULL);
		}
	}
	else {
		/* Display is non-NULL, copy the pointer */
		display_name = (char *)display;
	}

	/* Attempt to allocate a display structure. Return NULL if allocation
	 * fails. */
	dpy = (Display *) Xcalloc(1, sizeof(Display) + sizeof(XCBConnection *));
	if (!dpy)
		goto error;
	dpy = (Display *) (((XCBConnection **) dpy) + 1);

	/* Initialize all the constant values in the Display structure. */
	memcpy(dpy, &_default_display, sizeof(Display));

	/* Call the Connect routine to get the transport connection object.
	 * If NULL is returned, the connection failed. The connect routine
	 * will set fullname to point to the expanded name. */
	dpy->fd = XCBOpen(display_name, &dpy->default_screen);
	if (dpy->fd == -1)
		goto error;

	/* FIXME: the nonce should be different for each connection. */
	c = XCBConnect(dpy->fd, dpy->default_screen, /* nonce */ 0);
	if (!c)
		goto error;
	XCBConnectionOfDisplay(dpy) = c;
	/* XXX: Xlib probably puts more in display_name. */
	dpy->display_name = strdup(display_name);

	/* Set up free-function record */
	dpy->free_funcs = (_XFreeFuncRec *)Xcalloc(1, sizeof(_XFreeFuncRec));
	if (!dpy->free_funcs)
		goto error;

	/* Initialize the display lock */
	if (InitDisplayLock(dpy) != 0)
		goto error;

	dpy->proto_major_version= c->setup->protocol_major_version;
	dpy->proto_minor_version= c->setup->protocol_minor_version;
	dpy->release 		= c->setup->release_number;
	dpy->resource_base	= c->setup->resource_id_base;
	dpy->resource_mask	= c->setup->resource_id_mask;
	dpy->motion_buffer	= c->setup->motion_buffer_size;
	dpy->max_request_size	= c->setup->maximum_request_length;
	dpy->nscreens		= c->setup->roots_len;
	dpy->nformats		= c->setup->pixmap_formats_len;
	dpy->byte_order		= c->setup->image_byte_order;
	dpy->bitmap_bit_order   = c->setup->bitmap_format_bit_order;
	dpy->bitmap_unit	= c->setup->bitmap_format_scanline_unit;
	dpy->bitmap_pad		= c->setup->bitmap_format_scanline_pad;
	dpy->min_keycode	= c->setup->min_keycode.id;
	dpy->max_keycode	= c->setup->max_keycode.id;

	{
		unsigned long mask;
		for (mask = dpy->resource_mask; !(mask & 1); mask >>= 1)
			++dpy->resource_shift;
	}
	dpy->resource_max = (dpy->resource_mask >> dpy->resource_shift) - 5;

	dpy->vendor = Xmalloc(c->setup->vendor_len + 1);
	memcpy(dpy->vendor, c->vendor, c->setup->vendor_len);
	dpy->vendor[c->setup->vendor_len] = '\0';

	if(!_XInitPixmapFormats(dpy) || !_XInitScreens(dpy))
		goto error;

	/* get the resource manager database off the root window. */
	LockDisplay(dpy);
	{
		XCBGetPropertyCookie cookie;
		XCBGetPropertyRep *r;

		cookie = XCBGetProperty(XCBConnectionOfDisplay(dpy), /* delete */ 0, XCLWINDOW(RootWindow(dpy, 0)), XCLATOM(XA_RESOURCE_MANAGER), XCLATOM(XA_STRING), /* offset */ 0, /* length */ 100000000L);
		r = XCBGetPropertyReply(XCBConnectionOfDisplay(dpy), cookie, 0);
		if(r)
		{
			/* reuse the returned memory for storing the string */
			int bytes = r->bytes_after;
			memmove(r, XCBGetPropertyvalue(r), bytes);
			dpy->xdefaults = (char *) r;
			dpy->xdefaults[bytes] = '\0';
		}
	}
	UnlockDisplay(dpy);

#ifdef XKB
	XkbUseExtension(dpy,NULL,NULL);
#endif

 	return(dpy);

error:
#if 0 /* XCB doesn't yet support disconnection */
	_XDisconnectDisplay (dpy->trans_conn);
#endif
	_XFreeDisplayStructure (dpy);
	return NULL;
}


/* XFreeDisplayStructure frees all the storage associated with a 
 * Display.  It is used by XOpenDisplay if it runs out of memory,
 * and also by XCloseDisplay.   It needs to check whether all pointers
 * are non-NULL before dereferencing them, since it may be called
 * by XOpenDisplay before the Display structure is fully formed.
 * XOpenDisplay must be sure to initialize all the pointers to NULL
 * before the first possible call on this.
 */

void _XFreeDisplayStructure(register Display *dpy)
{
	while (dpy->ext_procs) {
	    _XExtension *ext = dpy->ext_procs;
	    dpy->ext_procs = ext->next;
	    if (ext->name)
		Xfree (ext->name);
	    Xfree ((char *)ext);
	}
	if (dpy->im_filters)
	   (*dpy->free_funcs->im_filters)(dpy);
	if (dpy->cms.clientCmaps)
	   (*dpy->free_funcs->clientCmaps)(dpy);
	if (dpy->cms.defaultCCCs)
	   (*dpy->free_funcs->defaultCCCs)(dpy);
	if (dpy->cms.perVisualIntensityMaps)
	   (*dpy->free_funcs->intensityMaps)(dpy);
	if (dpy->atoms)
	    (*dpy->free_funcs->atoms)(dpy);
	if (dpy->modifiermap)
	   (*dpy->free_funcs->modifiermap)(dpy->modifiermap);
	if (dpy->key_bindings)
	   (*dpy->free_funcs->key_bindings)(dpy);
	if (dpy->context_db)
	   (*dpy->free_funcs->context_db)(dpy);
	if (dpy->xkb_info)
	   (*dpy->free_funcs->xkb)(dpy);

	if (dpy->screens) {
	    register int i;

            for (i = 0; i < dpy->nscreens; i++) {
		Screen *sp = &dpy->screens[i];

		if (sp->depths) {
		   register int j;

		   for (j = 0; j < sp->ndepths; j++) {
			Depth *dp = &sp->depths[j];

			if (dp->visuals) {
			   register int k;

			   for (k = 0; k < dp->nvisuals; k++)
			     _XFreeExtData (dp->visuals[k].ext_data);
			   Xfree ((char *) dp->visuals);
			   }
			}

		   Xfree ((char *) sp->depths);
		   }

		_XFreeExtData (sp->ext_data);
		}

	    Xfree ((char *)dpy->screens);
	    }
	
	if (dpy->pixmap_format) {
	    register int i;

	    for (i = 0; i < dpy->nformats; i++)
	      _XFreeExtData (dpy->pixmap_format[i].ext_data);
            Xfree ((char *)dpy->pixmap_format);
	    }

	if (dpy->display_name)
	   Xfree (dpy->display_name);
	if (dpy->vendor)
	   Xfree (dpy->vendor);

        if (dpy->buffer)
	   Xfree (dpy->buffer);
	if (dpy->keysyms)
	   Xfree ((char *) dpy->keysyms);
	if (dpy->xdefaults)
	   Xfree (dpy->xdefaults);
	if (dpy->error_vec)
	    Xfree ((char *)dpy->error_vec);

	_XFreeExtData (dpy->ext_data);
	if (dpy->free_funcs)
	    Xfree ((char *)dpy->free_funcs);
 	if (dpy->scratch_buffer)
 	    Xfree (dpy->scratch_buffer);
	FreeDisplayLock(dpy);

	if (dpy->qfree) {
	    register _XQEvent *qelt = dpy->qfree;

	    while (qelt) {
		register _XQEvent *qnxt = qelt->next;
		Xfree ((char *) qelt);
		qelt = qnxt;
	    }
	}
	while (dpy->im_fd_info) {
	    struct _XConnectionInfo *conni = dpy->im_fd_info;
	    dpy->im_fd_info = conni->next;
	    if (conni->watch_data)
		Xfree (conni->watch_data);
	    Xfree (conni);
	}
	if (dpy->conn_watchers) {
	    struct _XConnWatchInfo *watcher = dpy->conn_watchers;
	    dpy->conn_watchers = watcher->next;
	    Xfree (watcher);
	}
	if (dpy->filedes)
	    Xfree (dpy->filedes);

	Xfree ((char *)dpy);
}

/* _XGetHostname - similar to gethostname but allows special processing. */
int _XGetHostname(char *buf, int maxlen)
{
    int len;

#ifdef NEED_UTSNAME
    struct utsname name;

    if (maxlen <= 0 || buf == NULL)
        return 0;

    uname (&name);
    len = strlen (name.nodename);
    if (len >= maxlen) len = maxlen - 1;
    strncpy (buf, name.nodename, len);
    buf[len] = '\0';
#else
    if (maxlen <= 0 || buf == NULL)
        return 0;

    buf[0] = '\0';
    (void) gethostname (buf, maxlen);
    buf [maxlen - 1] = '\0';
    len = strlen(buf);
#endif /* NEED_UTSNAME */
    return len;
}

/* Given a visual id, find the visual structure for this id on this display. */
Visual *_XVIDtoVisual(Display *dpy, VisualID id)
{
        register int i, j, k;
        register Screen *sp;
        register Depth *dp;
        register Visual *vp;
        for (i = 0; i < dpy->nscreens; i++) {
                sp = &dpy->screens[i];
                for (j = 0; j < sp->ndepths; j++) {
                        dp = &sp->depths[j];
                        /* if nvisuals == 0 then visuals will be NULL */
                        for (k = 0; k < dp->nvisuals; k++) {
                                vp = &dp->visuals[k];
                                if (vp->visualid == id) return (vp);
                        }
                }
        }
        return (NULL);
}
