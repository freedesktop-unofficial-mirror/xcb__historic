/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCBINT_H
#define __XCBINT_H

/* xcb_auth.c */

/* Maximum size of authentication names and data */
#define AUTHNAME_MAX 256
#define AUTHDATA_MAX 256

struct XCBAuthInfo {
    int namelen;
    char name[AUTHNAME_MAX];
    int datalen;
    char data[AUTHDATA_MAX];
};

XCBAuthInfo *XCBGetAuthInfo(int fd, int nonce, XCBAuthInfo *info);


/* xcb_io.c */

/* Index of nearest 4-byte boundary following E. */
#define XCB_CEIL(E) (((E)+3)&~3)

#define XCB_PAD(i) ((4 - (i & 3)) & 3)

typedef int (*XCBIOCallback)(void *data, XCBIOHandle *h);

XCBIOHandle *XCBIOFdOpen(int fd, pthread_mutex_t *locked);
void XCBIOSetReader(XCBIOHandle *h, XCBIOCallback reader, void *readerdata);

void *XCBAllocOut(XCBIOHandle *c, int size);

int XCBFillBuffer(XCBIOHandle *h);
int XCBWait(XCBIOHandle *c, const int should_write);
int XCBFlushLocked(XCBIOHandle *c);

int XCBWrite(XCBIOHandle *c, struct iovec *vector, size_t count);
int XCBRead(XCBIOHandle *h, void *buf, int nread);
int XCBIOPeek(XCBIOHandle *h, void *buf, int nread);
int XCBIOReadable(XCBIOHandle *h);

/* xcb_list.c */

typedef void (*XCBListFreeFunc)(void *);

XCBList *XCBListNew(void);
void XCBListClear(XCBList *list, XCBListFreeFunc do_free);
void XCBListDelete(XCBList *list, XCBListFreeFunc do_free);
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
