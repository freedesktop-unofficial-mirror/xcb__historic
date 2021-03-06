/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

#ifdef MIN		/* some systems define this in <sys/param.h> */
#undef MIN
#endif
#define MIN(a, b) ((a) < (b) ? (a) : (b))

#if 0 /* not needed yet */
int XGetPointerMapping (dpy, map, nmaps)
    register Display *dpy;
    unsigned char *map;	/* RETURN */
    int nmaps;

{
    unsigned char mapping[256];	/* known fixed size */
    long nbytes, remainder = 0;
    xGetPointerMappingReply rep;
    register xReq *req;

    LockDisplay(dpy);
    GetEmptyReq(GetPointerMapping, req);
    if (! _XReply(dpy, (xReply *)&rep, 0, xFalse)) {
	UnlockDisplay(dpy);
	SyncHandle();
	return 0;
    }

    nbytes = (long)rep.length << 2;

    /* Don't count on the server returning a valid value */
    if (nbytes > sizeof mapping) {
	remainder = nbytes - sizeof mapping;
	nbytes = sizeof mapping;
    }
    _XRead (dpy, (char *)mapping, nbytes);
    /* don't return more data than the user asked for. */
    if (rep.nElts) {
	    memcpy ((char *) map, (char *) mapping, 
		MIN((int)rep.nElts, nmaps) );
	}

    if (remainder) 
	_XEatData(dpy, (unsigned long)remainder);

    UnlockDisplay(dpy);
    SyncHandle();
    return ((int) rep.nElts);
}
#endif

KeySym *XGetKeyboardMapping (Display *dpy,
#if NeedWidePrototypes
			     unsigned int first_keycode,
#else
			     KeyCode first_keycode,
#endif
			     int count, int *keysyms_per_keycode)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetKeyboardMappingRep *r;

    r = XCBGetKeyboardMappingReply(c, XCBGetKeyboardMapping(c, XCLKEYCODE(first_keycode), count), 0);
    if (!r)
	return 0;

    *keysyms_per_keycode = r->keysyms_per_keycode;
    memmove(r, XCBGetKeyboardMappingkeysyms(r), XCBGetKeyboardMappingkeysymsLength(r));
    return (KeySym *) r;
}
