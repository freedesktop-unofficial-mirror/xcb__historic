/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef REPLY_FORMATS_H
#define REPLY_FORMATS_H

#include <X11/XCB/xcb.h>

int formatGetWindowAttributesReply(WINDOW wid, XCBGetWindowAttributesRep *reply);
int formatGetGeometryReply(WINDOW wid, XCBGetGeometryRep *reply);
int formatQueryTreeReply(WINDOW wid, XCBQueryTreeRep *reply);
int formatEvent(XCBGenericEvent *e);

#endif /* REPLY_FORMATS_H */
