/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_LIST_H
#define __XCB_LIST_H
#include <xcb_trace.h>

typedef struct XCBList XCBList;

/* Linked list functions */

XCBList *XCBListNew();
void XCBListInsert(XCBList *list, void *data);
void XCBListAppend(XCBList *list, void *data);
void *XCBListRemoveHead(XCBList *list);
void *XCBListRemove(XCBList *list, int (*cmp)(const void *, const void *), const void *data);
void *XCBListFind(XCBList *list, int (*cmp)(const void *, const void *), const void *data);
int XCBListIsEmpty(XCBList *list);
#endif
