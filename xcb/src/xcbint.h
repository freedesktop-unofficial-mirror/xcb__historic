/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCBINT_H
#define __XCBINT_H
#include <stdlib.h>

/* xcb_io.c */

/* Index of nearest 4-byte boundary following E. */
#define XCB_CEIL(E) (((E)+3)&~3)

XCBIOHandle *XCBIOFdOpen(int fd, pthread_mutex_t *locked);
void XCBIOSetReader(XCBIOHandle *h, int (*reader)(void *, XCBIOHandle *), void *readerdata);

void *XCBAllocOut(XCBIOHandle *c, int size);

int XCBWait(XCBIOHandle *c, const int should_write);
int XCBFillBufferLocked(XCBIOHandle *h);
int XCBFlushLocked(XCBIOHandle *c);

int XCBWrite(XCBIOHandle *c, struct iovec *vector, size_t count);
int XCBRead(XCBIOHandle *h, void *buf, int nread);
int XCBIOPeek(XCBIOHandle *h, void *buf, int nread);
int XCBIOReadable(XCBIOHandle *h);

/* xcb_list.c */

XCBList *XCBListNew();
void XCBListInsert(XCBList *list, void *data);
void XCBListAppend(XCBList *list, void *data);
void *XCBListRemoveHead(XCBList *list);
void *XCBListRemove(XCBList *list, int (*cmp)(const void *, const void *), const void *data);
void *XCBListFind(XCBList *list, int (*cmp)(const void *, const void *), const void *data);
int XCBListLength(XCBList *list);
int XCBListIsEmpty(XCBList *list);

/* Tracing definitions */

#ifndef XCBTRACEREQ
#define XCBTRACEREQ 0
#endif

#ifndef XCBTRACEMARSHAL
#define XCBTRACEMARSHAL 0
#endif

#ifndef XCBTRACEREP
#define XCBTRACEREP 0
#endif

#ifndef XCBTRACEEVENT
#define XCBTRACEEVENT 0
#endif

#if XCBTRACEREQ || XCBTRACEMARSHAL || XCBTRACEREP || XCBTRACEEVENT
#include <stdio.h>
#endif

#if XCBTRACEREP
#define XCBREPTRACER(id) fputs(id " reply wait\n", stderr);
#else
#define XCBREPTRACER(id)
#endif

#if XCBTRACEREQ
#define XCBREQTRACER(id) fputs(id " request send\n", stderr);
#else
#define XCBREQTRACER(id)
#endif

#if XCBTRACEMARSHAL
#define XCBMARSHALTRACER(id) fputs(id " request marshaled\n", stderr);
#else
#define XCBMARSHALTRACER(id)
#endif

#endif
