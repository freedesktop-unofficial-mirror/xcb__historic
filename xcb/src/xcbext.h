/*
 * Copyright (C) 2001-2004 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCBEXT_H
#define __XCBEXT_H

#ifdef __cplusplus
extern "C" {
#endif

/* xcb_out.c */

int XCBSendRequest(XCBConnection *c, unsigned int *request, int isvoid, struct iovec *vector, size_t count);


/* xcb_in.c */

void *XCBWaitReply(XCBConnection *c, unsigned int request, XCBGenericError **e);


/* xcb_xid.c */

CARD32 XCBGenerateID(XCBConnection *c);


/* xcb_util.c */

int XCBPopcount(CARD32 mask);

#ifdef __cplusplus
}
#endif

#endif
