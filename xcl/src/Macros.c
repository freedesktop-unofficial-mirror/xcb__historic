/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1987, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
/*
 * This file makes full definitions of routines for each macro.
 * We do not expect C programs to use these, but other languages may
 * need them.
 */

int XConnectionNumber(Display *dpy) { return (ConnectionNumber(dpy)); }

Window XRootWindow(Display *dpy, int scr) { return (RootWindow(dpy,scr)); }

int XDefaultScreen(Display *dpy) { return (DefaultScreen(dpy)); }

Window XDefaultRootWindow(Display *dpy)
	{ return (RootWindow(dpy,DefaultScreen(dpy))); }

Visual *XDefaultVisual(Display *dpy, int scr)
	{ return (DefaultVisual(dpy, scr)); }

GC XDefaultGC(Display *dpy, int scr) { return (DefaultGC(dpy,scr)); }

unsigned long XBlackPixel(Display *dpy, int scr)
	{ return (BlackPixel(dpy, scr)); }

unsigned long XWhitePixel(Display *dpy, int scr)
	{ return (WhitePixel(dpy,scr)); }

unsigned long XAllPlanes() { return AllPlanes; }

int XQLength(Display *dpy) { return (QLength(dpy)); }

int XDisplayWidth(Display *dpy, int scr)
	{ return (DisplayWidth(dpy,scr)); }

int XDisplayHeight(Display *dpy, int scr)
	{ return (DisplayHeight(dpy, scr)); }

int XDisplayWidthMM(Display *dpy, int scr)
	{ return (DisplayWidthMM(dpy, scr)); }

int XDisplayHeightMM(Display *dpy, int scr)
	{ return (DisplayHeightMM(dpy, scr)); }

int XDisplayPlanes(Display *dpy, int scr)
	{ return (DisplayPlanes(dpy, scr)); }

int XDisplayCells(Display *dpy, int scr)
	{ return (DisplayCells (dpy, scr)); }

int XScreenCount(Display *dpy) { return (ScreenCount(dpy)); }

char *XServerVendor(Display *dpy) { return (ServerVendor(dpy)); }

int XProtocolVersion(Display *dpy) { return (ProtocolVersion(dpy)); }

int XProtocolRevision(Display *dpy) { return (ProtocolRevision(dpy)); }

int XVendorRelease(Display *dpy) { return (VendorRelease(dpy)); }

char *XDisplayString(Display *dpy) { return (DisplayString(dpy)); }

int XDefaultDepth(Display *dpy, int scr)
	{ return (DefaultDepth(dpy, scr)); }

Colormap XDefaultColormap(Display *dpy, int scr)
	{ return (DefaultColormap(dpy, scr)); }

int XBitmapUnit(Display *dpy) { return (BitmapUnit(dpy)); }

int XBitmapBitOrder(Display *dpy) { return (BitmapBitOrder(dpy)); }

int XBitmapPad(Display *dpy) { return (BitmapPad(dpy)); }

int XImageByteOrder(Display *dpy) { return (ImageByteOrder(dpy)); }

unsigned long XNextRequest(Display *dpy)
{
#ifdef WORD64
    WORD64ALIGN
    return dpy->request + 1;
#else
    return (NextRequest(dpy));
#endif
}

unsigned long XLastKnownRequestProcessed(Display *dpy)
    { return (LastKnownRequestProcessed(dpy)); }

/* screen oriented macros (toolkit) */
Screen *XScreenOfDisplay(Display *dpy, int scr)
	{ return (ScreenOfDisplay(dpy, scr)); }

Screen *XDefaultScreenOfDisplay(Display *dpy)
	{ return (DefaultScreenOfDisplay(dpy)); }

Display *XDisplayOfScreen(Screen *s) { return (DisplayOfScreen(s)); }

Window XRootWindowOfScreen(Screen *s) { return (RootWindowOfScreen(s)); }

unsigned long XBlackPixelOfScreen(Screen *s)
	{ return (BlackPixelOfScreen(s)); }

unsigned long XWhitePixelOfScreen(Screen *s)
	{ return (WhitePixelOfScreen(s)); }

Colormap XDefaultColormapOfScreen(Screen *s)
	{ return (DefaultColormapOfScreen(s)); }

int XDefaultDepthOfScreen(Screen *s) { return (DefaultDepthOfScreen(s)); }

GC XDefaultGCOfScreen(Screen *s) { return (DefaultGCOfScreen(s)); }

Visual *XDefaultVisualOfScreen(Screen *s)
	{ return (DefaultVisualOfScreen(s)); }

int XWidthOfScreen(s) Screen *s; { return (WidthOfScreen(s)); }

int XHeightOfScreen(s) Screen *s; { return (HeightOfScreen(s)); }

int XWidthMMOfScreen(s) Screen *s; { return (WidthMMOfScreen(s)); }

int XHeightMMOfScreen(s) Screen *s; { return (HeightMMOfScreen(s)); }

int XPlanesOfScreen(s) Screen *s; { return (PlanesOfScreen(s)); }

int XCellsOfScreen(s) Screen *s; { return (CellsOfScreen(s)); }

int XMinCmapsOfScreen(s) Screen *s; { return (MinCmapsOfScreen(s)); }

int XMaxCmapsOfScreen(s) Screen *s; { return (MaxCmapsOfScreen(s)); }

Bool XDoesSaveUnders(s) Screen *s; { return (DoesSaveUnders(s)); }

int XDoesBackingStore(s) Screen *s; { return (DoesBackingStore(s)); }

long XEventMaskOfScreen(s) Screen *s; { return (EventMaskOfScreen(s)); }

int XScreenNumberOfScreen (register Screen *scr)
{
    register Display *dpy = scr->display;
    register Screen *dpyscr = dpy->screens;
    register int i;

    for (i = 0; i < dpy->nscreens; i++, dpyscr++) {
	if (scr == dpyscr) return i;
    }
    return -1;
}

/*
 * These macros are used to give some sugar to the image routines so that
 * naive people are more comfortable with them.
 */
#undef XDestroyImage
int
XDestroyImage(ximage)
	XImage *ximage;
{
	return((*((ximage)->f.destroy_image))((ximage)));
}
#undef XGetPixel
unsigned long XGetPixel(ximage, x, y)
	XImage *ximage;
	int x, y;
{
	return ((*((ximage)->f.get_pixel))((ximage), (x), (y)));
}
#undef XPutPixel
int XPutPixel(ximage, x, y, pixel)
	XImage *ximage;
	int x, y;
	unsigned long pixel;
{
	return((*((ximage)->f.put_pixel))((ximage), (x), (y), (pixel)));
}
#undef XSubImage
XImage *XSubImage(ximage, x, y, width, height)
	XImage *ximage;
	int x, y;
	unsigned int width, height;
{
	return((*((ximage)->f.sub_image))((ximage), (x),
		(y), (width), (height)));
}
#undef XAddPixel
int XAddPixel(ximage, value)
	XImage *ximage;
	long value;
{
	return((*((ximage)->f.add_pixel))((ximage), (value)));
}

int XNoOp (Display *dpy)
{
    XCBNoOperation(XCBConnectionOfDisplay(dpy));
    return 1;
}
