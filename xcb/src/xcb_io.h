/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_IO_H
#define __XCB_IO_H
#include <xcb_trace.h>

#include <sys/uio.h>
#include <pthread.h>

/* Index of nearest 4-byte boundary following E. */
#define XCB_CEIL(E) (((E)+3)&~3)

/* X_TCP_PORT + display number = server port for TCP transport */
#define X_TCP_PORT 6000

typedef struct XCBIOHandle XCBIOHandle;

XCBIOHandle *XCBIOFdOpen(int fd, pthread_mutex_t *locked, int (*reader)(void *, XCBIOHandle *), void *readerdata);

void *XCBAllocOut(XCBIOHandle *c, int size);

int XCBWait(XCBIOHandle *c, const int should_write);
int XCBFlushLocked(XCBIOHandle *c);

int XCBWrite(XCBIOHandle *c, struct iovec *vector, size_t count);
int XCBRead(XCBIOHandle *h, void *buf, int nread);
int XCBIOPeek(XCBIOHandle *h, void *buf, int nread);
int XCBIOReadable(XCBIOHandle *h);

int XCBOpen(const char *display, int *screen);
int XCBOpenTCP(const char *host, unsigned short port);
int XCBOpenUnix(const char *file);
#endif
