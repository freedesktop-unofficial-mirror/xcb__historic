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
    XCBGetPropertyCookie c;
    XCBGetPropertyRep *r;

    c = XCBGetProperty(XCBConnectionOfDisplay(dpy), delete, XCLWINDOW(window), XCLATOM(property), XCLATOM(req_type), offset, length);
    r = XCBGetPropertyReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (!r)
	return 1;	/* not Success */

    *prop = (unsigned char *) NULL;
    if (r->type.xid != None) {
	/* Check that the server returned a valid format. If it didn't,
	 * throw a BadImplementation error in the library. */
	switch (r->format) {
	    xError error;

	    case 8: case 16: case 32:
		/* format is valid */
		break;

	    default:
		error.type = X_Error;
		error.sequenceNumber = c.seqnum;
		error.majorCode = X_GetProperty;
		error.minorCode = 0;
		error.errorCode = BadImplementation;
		_XError(dpy, &error);
		goto error;
	}
	/* One more byte is malloced than is needed to contain the property
	 * data, but this last byte is null terminated and convenient for 
	 * returning string properties, so the client doesn't then have to 
	 * recopy the string to make it null terminated. On the other hand,
	 * it's a really stupid idea. */
	*prop = Xmalloc (r->bytes_after + 1);
	if (!*prop)
	    goto error;
	/* FIXME: Xlib has a different behavior than this for systems where a
	 * short isn't 16 bits or where a long isn't 32 bits. */
	memcpy (*prop, XCBGetPropertyvalue(r), r->bytes_after);
	(*prop)[r->bytes_after] = '\0';
    }

    *actual_type = r->type.xid;
    *actual_format = r->format;
    *nitems = r->value_len;
    *bytesafter = r->bytes_after;
    free(r);
    return Success;

error:
    free(r);
    return BadAlloc;	/* not Success */
}
