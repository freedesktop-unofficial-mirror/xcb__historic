/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_CONN_H
#define __XCB_CONN_H
#include <X11/XCB/xcb_trace.h>

#include <X11/XCB/xcb_list.h>
#include <X11/XCB/xcb_types.h>
#include <X11/XCB/xcb_io.h>
#include <sys/uio.h>
#include <pthread.h>

/* Pre-defined constants */

/* `current protocol version' */
#define X_PROTOCOL 11

/* `current minor version' */
#define X_PROTOCOL_REVISION 0

/* Maximum size of authentication names and data */
#define AUTHNAME_MAX 256
#define AUTHDATA_MAX 256







/* Utility functions */




/* Specific list implementations */

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */














typedef struct XCBReplyData {
    int pending;
    int error;
    int seqnum;
    void *data;
} XCBReplyData;

typedef struct XCBReplyDataIter {
    XCBReplyData *data;
    int rem;
} XCBReplyDataIter;

typedef struct XCBAuthInfo {
    int namelen;
    char name[AUTHNAME_MAX];
    int datalen;
    char data[AUTHDATA_MAX];
} XCBAuthInfo;

typedef struct XCBAuthInfoIter {
    XCBAuthInfo *data;
    int rem;
} XCBAuthInfoIter;

typedef struct XCBConnection {
    pthread_mutex_t locked;
    XCBIOHandle *handle;
    XCBList *reply_data;
    XCBList *event_data;
    XCBList *extension_cache;
    void *last_request;
    unsigned int seqnum;
    unsigned int seqnum_written;
    CARD32 last_xid;
    XCBConnSetupSuccessRep *setup;
} XCBConnection;

typedef struct XCBConnectionIter {
    XCBConnection *data;
    int rem;
} XCBConnectionIter;

void *XCBReplyDataAfterIter(XCBReplyDataIter i);
void *XCBAuthInfoAfterIter(XCBAuthInfoIter i);
void *XCBConnectionAfterIter(XCBConnectionIter i);
int XCBOnes(unsigned long mask);
CARD32 XCBGenerateID(XCBConnection *c);
void XCBAddReplyData(XCBConnection *c, int seqnum);
void *XCBWaitSeqnum(XCBConnection *c, unsigned int seqnum, XCBGenericEvent **e);
XCBGenericEvent *XCBWaitEvent(XCBConnection *c);
XCBGenericEvent *XCBPollEvent(XCBConnection *c);
int XCBFlush(XCBConnection *c);
XCBAuthInfo *XCBGetAuthInfo(int fd, int nonce, XCBAuthInfo *info);
XCBConnection *XCBConnect(int fd, int screen, int nonce);
XCBConnection *XCBConnectAuth(int fd, XCBAuthInfo *auth_info);
XCBConnection *XCBConnectBasic();
static inline void XCBReplyDataNext(XCBReplyDataIter *i)
{
    XCBReplyData *R = i->data;
    --i->rem;
    i->data = (XCBReplyData *) (R + 1);
}

static inline void XCBAuthInfoNext(XCBAuthInfoIter *i)
{
    XCBAuthInfo *R = i->data;
    --i->rem;
    i->data = (XCBAuthInfo *) (R + 1);
}

static inline void XCBConnectionNext(XCBConnectionIter *i)
{
    XCBConnection *R = i->data;
    --i->rem;
    i->data = (XCBConnection *) (R + 1);
}

#endif
