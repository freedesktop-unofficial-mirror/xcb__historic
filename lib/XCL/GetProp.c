/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int
XGetWindowProperty(register Display *dpy, Window window, Atom property, long offset, long length, Bool delete, Atom req_type,
    /* RETURNS */
    Atom *actual_type, int *actual_format, unsigned long *nitems, unsigned long *bytesafter, unsigned char **prop)
{
    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetPropertyCookie cookie;
    XCBGetPropertyRep *r;

    cookie = XCBGetProperty(c, delete, XCLWINDOW(window), XCLATOM(property), XCLATOM(req_type), offset, length);
    r = XCBGetPropertyReply(c, cookie, 0);
    if (!r)
	return 1;	/* not Success */

    /* XXX: should we even bother checking r->format? */
    if (r->type.xid != None)
    {
	/* Check that the server returned a valid format. If it didn't,
	 * throw a BadImplementation error in the library. */
	switch (r->format) {
	    xError error;

	    case 8: case 16: case 32:
		/* format is valid */
		break;

	    default:
		error.type = X_Error;
		error.sequenceNumber = cookie.seqnum;
		error.majorCode = X_GetProperty;
		error.minorCode = 0;
		error.errorCode = BadImplementation;
		_XError(dpy, &error);
		goto error;
	}
    }

    *actual_type = r->type.xid;
    *actual_format = r->format;
    *nitems = r->value_len;
    *bytesafter = r->bytes_after;

    if (r->type.xid != None)
    {
	/* This null terminates the property, which is convenient for 
	 * returning string properties, so the client doesn't then have to 
	 * recopy the string to make it null terminated. On the other hand,
	 * it's a really stupid idea. */
	long bytes = XCBGetPropertyvalueLength(r);
	/* FIXME: Xlib has a different behavior than this for systems where a
	 * short isn't 16 bits or where a long isn't 32 bits. */
	memmove(r, XCBGetPropertyvalue(r), bytes);
	*prop = (char *) r;
	(*prop)[bytes] = '\0';
    }
    else
    {
	*prop = 0;
	free(r);
    }

    return Success;

error:
    free(r);
    return BadAlloc;	/* not Success */
}
