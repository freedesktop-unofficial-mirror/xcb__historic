#include "xclint.h"

static XGCValues const initial_GC = {
    GXcopy, 	/* function */
    AllPlanes,	/* plane_mask */
    0L,		/* foreground */
    1L,		/* background */
    0,		/* line_width */
    LineSolid,	/* line_style */
    CapButt,	/* cap_style */
    JoinMiter,	/* join_style */
    FillSolid,	/* fill_style */
    EvenOddRule,/* fill_rule */
    ArcPieSlice,/* arc_mode */
    (Pixmap)~0L,/* tile, impossible (unknown) resource */
    (Pixmap)~0L,/* stipple, impossible (unknown) resource */
    0,		/* ts_x_origin */
    0,		/* ts_y_origin */
    (Font)~0L,	/* font, impossible (unknown) resource */
    ClipByChildren, /* subwindow_mode */
    True,	/* graphics_exposures */
    0,		/* clip_x_origin */
    0,		/* clip_y_origin */
    None,	/* clip_mask */
    0,		/* dash_offset */
    4		/* dashes (list [4,4]) */
};

static void _XGenerateGCList();
int _XUpdateGCCache();

/* drawable: Window or Pixmap for which depth matches */
/* valuemask: which ones to set initially */
/* gcvalues: the values themselves */
GC XCreateGC(register Display *dpy, Drawable drawable, unsigned long valuemask, XGCValues *gcvalues)
{
    register GC gc;
    register _XExtension *ext;
    GCONTEXT g;
    CARD32 values[32];

    LockDisplay(dpy);
    gc = (GC)Xmalloc (sizeof(struct _XGC));
    if (gc == NULL)
	goto done;
    g = XCBGCONTEXTNew(XCBConnectionOfDisplay(dpy));

    gc->gid = g.xid;
    gc->rects = 0;
    gc->dashes = 0;
    gc->ext_data = NULL;
    gc->values = initial_GC;
    gc->dirty = 0L;

    valuemask &= (1L << (GCLastBit + 1)) - 1;
    if (valuemask)
	_XUpdateGCCache (gc, valuemask, gcvalues);
    if (gc->dirty)
	_XGenerateGCList (&gc->values, gc->dirty, values);
    XCBCreateGC(XCBConnectionOfDisplay(dpy), g, XCLDRAWABLE(drawable), gc->dirty, values);

    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->create_GC) (*ext->create_GC)(dpy, gc, &ext->codes);
    gc->dirty = 0L; /* allow extensions to see dirty bits */

done:
    UnlockDisplay(dpy);
    return (gc);
}

int _XUpdateGCCache(register GC gc, register unsigned long mask, register XGCValues *attr)
{
    register XGCValues *gv = &gc->values;

    if (mask & GCFunction)
        if (gv->function != attr->function)
	    gv->function = attr->function;
	else
	    mask &= ~GCFunction;
	
    if (mask & GCPlaneMask)
        if (gv->plane_mask != attr->plane_mask)
            gv->plane_mask = attr->plane_mask;
	else
	    mask &= ~GCPlaneMask;

    if (mask & GCForeground)
        if (gv->foreground != attr->foreground)
            gv->foreground = attr->foreground;
	else
	    mask &= ~GCForeground;

    if (mask & GCBackground)
        if (gv->background != attr->background)
            gv->background = attr->background;
	else
	    mask &= ~GCBackground;

    if (mask & GCLineWidth)
        if (gv->line_width != attr->line_width)
            gv->line_width = attr->line_width;
	else
	    mask &= ~GCLineWidth;

    if (mask & GCLineStyle)
        if (gv->line_style != attr->line_style)
            gv->line_style = attr->line_style;
	else
	    mask &= ~GCLineStyle;

    if (mask & GCCapStyle)
        if (gv->cap_style != attr->cap_style)
            gv->cap_style = attr->cap_style;
	else
	    mask &= ~GCCapStyle;
    
    if (mask & GCJoinStyle)
        if (gv->join_style != attr->join_style)
            gv->join_style = attr->join_style;
	else
	    mask &= ~GCJoinStyle;

    if (mask & GCFillStyle)
        if (gv->fill_style != attr->fill_style)
            gv->fill_style = attr->fill_style;
	else
	    mask &= ~GCFillStyle;

    if (mask & GCFillRule)
        if (gv->fill_rule != attr->fill_rule)
    	    gv->fill_rule = attr->fill_rule;
	else
	    mask &= ~GCFillRule;

    if (mask & GCArcMode)
        if (gv->arc_mode != attr->arc_mode)
	    gv->arc_mode = attr->arc_mode;
	else
	    mask &= ~GCArcMode;

    /* always write through tile change, since client may have changed pixmap contents */
    if (mask & GCTile)
	gv->tile = attr->tile;

    /* always write through stipple change, since client may have changed pixmap contents */
    if (mask & GCStipple)
	gv->stipple = attr->stipple;

    if (mask & GCTileStipXOrigin)
        if (gv->ts_x_origin != attr->ts_x_origin)
    	    gv->ts_x_origin = attr->ts_x_origin;
	else
	    mask &= ~GCTileStipXOrigin;

    if (mask & GCTileStipYOrigin)
        if (gv->ts_y_origin != attr->ts_y_origin)
	    gv->ts_y_origin = attr->ts_y_origin;
	else
	    mask &= ~GCTileStipYOrigin;

    if (mask & GCFont)
        if (gv->font != attr->font)
	    gv->font = attr->font;
	else
	    mask &= ~GCFont;

    if (mask & GCSubwindowMode)
        if (gv->subwindow_mode != attr->subwindow_mode)
	    gv->subwindow_mode = attr->subwindow_mode;
	else
	    mask &= ~GCSubwindowMode;

    if (mask & GCGraphicsExposures)
        if (gv->graphics_exposures != attr->graphics_exposures)
	    gv->graphics_exposures = attr->graphics_exposures;
	else
	    mask &= ~GCGraphicsExposures;

    if (mask & GCClipXOrigin)
        if (gv->clip_x_origin != attr->clip_x_origin)
	    gv->clip_x_origin = attr->clip_x_origin;
	else
	    mask &= ~GCClipXOrigin;

    if (mask & GCClipYOrigin)
        if (gv->clip_y_origin != attr->clip_y_origin)
	    gv->clip_y_origin = attr->clip_y_origin;
	else
	    mask &= ~GCClipYOrigin;

    /* always write through mask change, since client may have changed pixmap contents */
    if (mask & GCClipMask) {
	gv->clip_mask = attr->clip_mask;
	gc->rects = 0;
    } 

    if (mask & GCDashOffset)
        if (gv->dash_offset != attr->dash_offset)
	    gv->dash_offset = attr->dash_offset;
	else
	    mask &= ~GCDashOffset;

    if (mask & GCDashList)
        if ((gv->dashes != attr->dashes) || (gc->dashes == True)) {
            gv->dashes = attr->dashes;
	    gc->dashes = 0;
	} else
	    mask &= ~GCDashList;

    gc->dirty |= mask;

    return 0;
}

/* can only call when display is already locked. */

void _XFlushGCCache(Display *dpy, GC gc)
{
    register _XExtension *ext;
    CARD32 values[32];

    if (!gc->dirty)
	return;

    _XGenerateGCList (&gc->values, gc->dirty, values);
    XCBChangeGC(XCBConnectionOfDisplay(dpy), XCLGCONTEXT(gc->gid), gc->dirty, values);

    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->flush_GC) (*ext->flush_GC)(dpy, gc, &ext->codes);
    gc->dirty = 0L; /* allow extensions to see dirty bits */
}

void XFlushGC(Display *dpy, GC gc)
{
    FlushGC(dpy, gc);
}

GContext XGContextFromGC(GC gc)
{
    return (gc->gid);
}

/*
 * GenerateGCList looks at the GC dirty bits, and appends all the required
 * long words to the request being generated.
 */

static void _XGenerateGCList(const XGCValues *gv, const unsigned long dirty, CARD32 values[32])
{
    register CARD32 *value = values;

    /*
     * Note: The order of these tests are critical; the order must be the
     * same as the GC mask bits in the word.
     */
    if (dirty & GCFunction)          *value++ = gv->function;
    if (dirty & GCPlaneMask)         *value++ = gv->plane_mask;
    if (dirty & GCForeground)        *value++ = gv->foreground;
    if (dirty & GCBackground)        *value++ = gv->background;
    if (dirty & GCLineWidth)         *value++ = gv->line_width;
    if (dirty & GCLineStyle)         *value++ = gv->line_style;
    if (dirty & GCCapStyle)          *value++ = gv->cap_style;
    if (dirty & GCJoinStyle)         *value++ = gv->join_style;
    if (dirty & GCFillStyle)         *value++ = gv->fill_style;
    if (dirty & GCFillRule)          *value++ = gv->fill_rule;
    if (dirty & GCTile)              *value++ = gv->tile;
    if (dirty & GCStipple)           *value++ = gv->stipple;
    if (dirty & GCTileStipXOrigin)   *value++ = gv->ts_x_origin;
    if (dirty & GCTileStipYOrigin)   *value++ = gv->ts_y_origin;
    if (dirty & GCFont)              *value++ = gv->font;
    if (dirty & GCSubwindowMode)     *value++ = gv->subwindow_mode;
    if (dirty & GCGraphicsExposures) *value++ = gv->graphics_exposures;
    if (dirty & GCClipXOrigin)       *value++ = gv->clip_x_origin;
    if (dirty & GCClipYOrigin)       *value++ = gv->clip_y_origin;
    if (dirty & GCClipMask)          *value++ = gv->clip_mask;
    if (dirty & GCDashOffset)        *value++ = gv->dash_offset;
    if (dirty & GCDashList)          *value++ = gv->dashes;
    if (dirty & GCArcMode)           *value++ = gv->arc_mode;
}
