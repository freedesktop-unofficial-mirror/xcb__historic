/*
 * Copyright (C) 2001-2004 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#ifndef __XCB_H
#define __XCB_H
#include <X11/Xmd.h>
#include <X11/X.h>
#include <sys/uio.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Pre-defined constants */

/* current protocol version */
#define X_PROTOCOL 11

/* current minor version */
#define X_PROTOCOL_REVISION 0

/* X_TCP_PORT + display number = server port for TCP transport */
#define X_TCP_PORT 6000

#define XCB_TYPE_PAD(T,I) (-(I) & (sizeof(T) > 4 ? 3 : sizeof(T) - 1))


/* Opaque structures */

typedef struct XCBConnection XCBConnection;


/* Other types */

typedef struct {
    void *data;
    int rem;
    int index;
} XCBGenericIter;

typedef struct {
    BYTE response_type;
    CARD8 pad0;
    CARD16 sequence;
    CARD32 length;
} XCBGenericRep;

typedef struct {
    BYTE response_type;
    CARD8 pad0;
    CARD16 sequence;
} XCBGenericEvent;

typedef struct {
    BYTE response_type;
    BYTE error_code;
    CARD16 sequence;
} XCBGenericError;

typedef struct {
    unsigned int sequence;
} XCBVoidCookie;


/* Include the generated xproto and xcb_types headers. */
#include "xcb_types.h"
#include "xproto.h"


/* xcb_auth.c */

typedef struct XCBAuthInfo {
    int namelen;
    char *name;
    int datalen;
    char *data;
} XCBAuthInfo;

int XCBGetAuthInfo(int fd, XCBAuthInfo *info);


/* xcb_out.c */

int XCBFlush(XCBConnection *c);


/* xcb_in.c */

XCBGenericEvent *XCBWaitEvent(XCBConnection *c);
XCBGenericEvent *XCBPollForEvent(XCBConnection *c, int *error);

int XCBEventQueueLength(XCBConnection *c);
void XCBEventQueueClear(XCBConnection *c);


/* xcb_ext.c */

typedef struct XCBExtension XCBExtension;

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBGetExtensionData(XCBConnection *c, XCBExtension *ext);

void XCBPrefetchExtensionData(XCBConnection *c, XCBExtension *ext);


/* xcb_conn.c */

XCBConnSetupSuccessRep *XCBGetSetup(XCBConnection *c);
int XCBGetFileDescriptor(XCBConnection *c);
CARD32 XCBGetMaximumRequestLength(XCBConnection *c);

XCBConnection *XCBConnect(int fd, XCBAuthInfo *auth_info);
void XCBDisconnect(XCBConnection *c);


/* xcb_util.c */

int XCBParseDisplay(const char *name, char **host, int *display, int *screen);
int XCBOpen(const char *host, int display);
int XCBOpenTCP(const char *host, unsigned short port);
int XCBOpenUnix(const char *file);

XCBConnection *XCBConnectBasic(void);

int XCBSync(XCBConnection *c, XCBGenericError **e);


#ifdef __cplusplus
}
#endif

#endif