/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_EVENT_H
#define __XCB_EVENT_H
#include <X11/XCB/xcb_trace.h>

struct XCBConnection;
#include <X11/XCB/xcb_types.h>

int XCBEventQueueIsEmpty(struct XCBConnection *c);
int XCBEventQueueLength(struct XCBConnection *c);

XCBGenericEvent *XCBEventQueueRemove(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data);

XCBGenericEvent *XCBEventQueueFind(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data);

void XCBEventQueueClear(struct XCBConnection *c);
#endif
