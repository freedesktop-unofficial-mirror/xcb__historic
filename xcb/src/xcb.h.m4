/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_H
#define __XCB_H
#include <X11/Xmd.h>
#include <X11/X.h>
#include <sys/uio.h>
#include <pthread.h>


/* Pre-defined constants */

/* current protocol version */
#define X_PROTOCOL 11

/* current minor version */
#define X_PROTOCOL_REVISION 0

/* X_TCP_PORT + display number = server port for TCP transport */
#define X_TCP_PORT 6000


/* Opaque structures */

typedef struct XCBAuthInfo XCBAuthInfo;
typedef struct XCBIOHandle XCBIOHandle;
typedef struct XCBList XCBList;


/* Other types */

typedef struct XCBGenericRep {
    BYTE response_type;
    CARD8 pad0;
    CARD16 seqnum;
    CARD32 length;
} XCBGenericRep;

typedef struct XCBGenericEvent {
    BYTE response_type;
} XCBGenericEvent;

typedef struct XCBGenericError {
    BYTE response_type;
    BYTE error_code;
    CARD16 seqnum;
} XCBGenericError;

typedef struct XCBVoidCookie {
    int seqnum;
} XCBVoidCookie;

divert(-1)
define(`_H')
include(`client-c.xcb')

define(`XCBGEN')
define(`ENDXCBGEN')

include(`xcb_types.xcb')
include(`xproto.xcb')
divert(0)dnl
undivert(TYPEDIV)dnl

/* xcb_auth.c */

int XCBNextNonce(void);


/* xcb_conn.c */

typedef int (*XCBUnexpectedReplyFunc)(void *unexpected_reply_data, XCBGenericRep *buf);

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

    XCBUnexpectedReplyFunc unexpected_reply_handler;
    void *unexpected_reply_data;

    XCBConnSetupSuccessRep *setup;
} XCBConnection;

int XCBOnes(unsigned long mask);
CARD32 XCBGenerateID(XCBConnection *c);
void XCBAddReplyData(XCBConnection *c, int seqnum);
void XCBSetUnexpectedReplyHandler(XCBConnection *c, XCBUnexpectedReplyFunc handler, void *data);
void *XCBWaitSeqnum(XCBConnection *c, unsigned int seqnum, XCBGenericEvent **e);
XCBGenericEvent *XCBWaitEvent(XCBConnection *c);
XCBGenericEvent *XCBPollEvent(XCBConnection *c);
int XCBFlush(XCBConnection *c);
XCBConnection *XCBConnect(int fd, int nonce);
XCBConnection *XCBConnectBasic(void);
void XCBDisconnect(XCBConnection *c);
int XCBParseDisplay(const char *name, char **host, int *display, int *screen);


/* xcb_event.c */

int XCBEventQueueIsEmpty(struct XCBConnection *c);
int XCBEventQueueLength(struct XCBConnection *c);

XCBGenericEvent *XCBEventQueueRemove(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data);

XCBGenericEvent *XCBEventQueueFind(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data);

void XCBEventQueueClear(struct XCBConnection *c);


/* xcb_io.c */

int XCBOpen(const char *host, int display);
int XCBOpenTCP(const char *host, unsigned short port);
int XCBOpenUnix(const char *file);


/* xproto.c and xcb_types.c */

undivert(FUNCDIV)
undivert(INLINEFUNCDIV)dnl

/* xcb_conn.c */

int XCBSync(XCBConnection *c, XCBGenericEvent **e);

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBQueryExtensionCached(XCBConnection *c, const char *name, XCBGenericEvent **e);

#endif
