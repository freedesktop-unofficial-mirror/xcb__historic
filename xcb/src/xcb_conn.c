/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <assert.h>
#include <netinet/in.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include "xcb.h"
#include "xcbint.h"

#undef USENONBLOCKING

typedef struct XCBReplyData {
    int pending;
    int error;
    int seqnum;
    void *data;
} XCBReplyData;

typedef struct XCBExtensionRecord {
    char *name;
    XCBQueryExtensionRep *info;
} XCBExtensionRecord;

int XCBOnes(unsigned long mask)
{
    register unsigned long y;
    y = (mask >> 1) & 033333333333;
    y = mask - y - ((y >> 1) & 033333333333);
    return ((y + (y >> 3)) & 030707070707) % 077;
}

CARD32 XCBGenerateID(XCBConnection *c)
{
    CARD32 ret;
    pthread_mutex_lock(&c->locked);
    ret = c->last_xid | c->setup->resource_id_base;
    c->last_xid += c->setup->resource_id_mask & -(c->setup->resource_id_mask);
    pthread_mutex_unlock(&c->locked);
    return ret;
}

void XCBAddReplyData(XCBConnection *c, int seqnum)
{
    XCBReplyData *data;
    data = (XCBReplyData *) malloc((1) * sizeof(XCBReplyData));
    assert(data);

    data->pending = 0;
    data->error = 0;
    data->seqnum = seqnum;
    data->data = 0;

    XCBListAppend(c->reply_data, data);
}

static void free_reply_data(XCBReplyData *data)
{
    free(data->data);
    free(data);
}

static int match_reply_seqnum16(const void *seqnum, const void *data)
{
    return ((CARD16) ((XCBReplyData *) data)->seqnum == (CARD16) *(int *) seqnum);
}

static int match_reply_seqnum32(const void *seqnum, const void *data)
{
    return (((XCBReplyData *) data)->seqnum == *(int *) seqnum);
}

void XCBSetUnexpectedReplyHandler(XCBConnection *c, XCBUnexpectedReplyFunc handler, void *data)
{
    c->unexpected_reply_handler = handler;
    c->unexpected_reply_data = data;
}

static /* PRE: called immediately after data has been read from the connection */
/* INV: this function operates entirely out of the I/O layer buffers,
        and never causes a read or write. */
int XCBReadPacket(void *readerdata, XCBIOHandle *h)
{
    XCBConnection *c = (XCBConnection *) readerdata;
    int ret;
    int length = 32;
    XCBGenericRep genrep;
    XCBReplyData *rep = 0;
    unsigned char *buf;

    /* Wait for there to be enough data for us to read a whole packet */
    if(XCBIOReadable(h) < length)
        return 0;

    XCBIOPeek(h, &genrep, sizeof(genrep));
    /* For reply packets, check that the entire packet is available. */
    if(genrep.response_type == 1)
        length += genrep.length * 4;

    buf = (unsigned char *) malloc((length) * sizeof(unsigned char));
    assert(buf);
    ret = XCBRead(h, buf, length);

    /* Only compare the low 16 bits of the seqnum of the packet. */
    if(!(buf[0] & ~1)) /* reply or error packet */
        rep = (XCBReplyData *) XCBListFind(c->reply_data, match_reply_seqnum16, &((XCBGenericRep *) buf)->seqnum);

    if(buf[0] == 1 && !rep) /* I see no reply record here, but I need one. */
    {
        int ret = -1;
        if(c->unexpected_reply_handler && c->unexpected_reply_handler(c->unexpected_reply_data, (XCBGenericRep *) buf))
            ret = 1;
        if(ret < 0)
            fprintf(stderr, "No reply record found for reply %d.\n", ((XCBGenericRep *) buf)->seqnum);
        free(buf);
        return ret;
    }

    if(rep) /* reply or error with a reply record. */
    {
        assert(rep->data == 0);
        rep->error = (buf[0] == 0);
        rep->data = buf;
    }
    else /* event or error without a reply record */
        XCBListAppend(c->event_data, (XCBGenericEvent *) buf);

    return 1; /* I have something for you... */
}

void *XCBWaitSeqnum(XCBConnection *c, unsigned int seqnum, XCBGenericError **e)
{
    void *ret = 0;
    XCBReplyData *cur;
    if(e)
        *e = 0;

    pthread_mutex_lock(&c->locked);
    /* If this request has not been written yet, write it. */
    if((signed int) (c->seqnum_written - seqnum) < 0)
    {
        if(XCBFlushLocked(c->handle) <= 0)
            goto done; /* error */
        c->last_request = 0;
        c->seqnum_written = c->seqnum;
    }

    /* Compare the sequence number as a full int. */
    cur = (XCBReplyData *) XCBListFind(c->reply_data, match_reply_seqnum32, &seqnum);

    if(!cur || cur->pending)
        goto done; /* error */

    ++cur->pending;

    while(!cur->data)
        if(XCBWait(c->handle, /*should_write*/ 0) <= 0)
        {
            /* Do not remove the reply record on I/O error. */
            --cur->pending;
            goto done;
        }

    /* No need to update pending flag - about to delete cur anyway. */

    if(cur->error)
    {
        if(!e)
            XCBListAppend(c->event_data, (XCBGenericEvent *) cur->data);
        else
            *e = (XCBGenericError *) cur->data;
    }
    else
        ret = cur->data;

    /* Compare the sequence number as a full int. */
    XCBListRemove(c->reply_data, match_reply_seqnum32, &seqnum);
    free(cur);

done:
    pthread_mutex_unlock(&c->locked);
    return ret;
}

XCBGenericEvent *XCBWaitEvent(XCBConnection *c)
{
    XCBGenericEvent *ret;

#if XCBTRACEEVENT
    fprintf(stderr, "Entering XCBWaitEvent\n");
#endif

    pthread_mutex_lock(&c->locked);
    while(XCBListIsEmpty(c->event_data))
        if(XCBWait(c->handle, /*should_write*/ 0) <= 0)
            break;
    /* XCBListRemoveHead returns 0 on empty list. */
    ret = (XCBGenericEvent *) XCBListRemoveHead(c->event_data);

    pthread_mutex_unlock(&c->locked);

#if XCBTRACEEVENT
    fprintf(stderr, "Leaving XCBWaitEvent, event type %d\n", ret ? ret->response_type : -1);
#endif

    return ret;
}

XCBGenericEvent *XCBPollEvent(XCBConnection *c)
{
    XCBGenericEvent *ret;

#if XCBTRACEEVENT
    fprintf(stderr, "Entering XCBPollEvent\n");
#endif

    pthread_mutex_lock(&c->locked);
    XCBFillBuffer(c->handle);
    /* XCBListRemoveHead returns 0 on empty list. */
    ret = (XCBGenericEvent *) XCBListRemoveHead(c->event_data);

    pthread_mutex_unlock(&c->locked);

#if XCBTRACEEVENT
    fprintf(stderr, "Leaving XCBPollEvent, event type %d\n", ret ? ret->response_type : -1);
#endif

    return ret;
}

int XCBFlush(XCBConnection *c)
{
    int ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBFlushLocked(c->handle);
    c->last_request = 0;
    c->seqnum_written = c->seqnum;
    pthread_mutex_unlock(&c->locked);
    return ret;
}

XCBConnection *XCBConnect(int fd, int nonce)
{
    XCBConnection* c;

    c = (XCBConnection *) malloc((1) * sizeof(XCBConnection));
    assert(c);

    pthread_mutex_init(&c->locked, 0);
    pthread_mutex_lock(&c->locked);

    c->handle = XCBIOFdOpen(fd, &c->locked);
    c->reply_data = XCBListNew();
    c->event_data = XCBListNew();
    c->extension_cache = XCBListNew();
    if(!(c->handle && c->reply_data && c->event_data && c->extension_cache))
        goto error;

    c->last_request = 0;
    c->seqnum = 0;
    c->seqnum_written = 0;
    c->last_xid = 0;

    c->unexpected_reply_handler = 0;
    c->unexpected_reply_data = 0;

    /* Write the connection setup request. */
    {
        XCBConnSetupReq *out = XCBAllocOut(c->handle, XCB_CEIL(sizeof(XCBConnSetupReq)));
        XCBAuthInfo auth, *auth_info;
        int endian = 0x01020304;

        /* B = 0x42 = MSB first, l = 0x6c = LSB first */
        if(htonl(endian) == endian)
            out->byte_order = 0x42;
        else
            out->byte_order = 0x6c;
        out->protocol_major_version = X_PROTOCOL;
        out->protocol_minor_version = X_PROTOCOL_REVISION;
        out->authorization_protocol_name_len = 0;
        out->authorization_protocol_data_len = 0;

        auth_info = XCBGetAuthInfo(fd, nonce, &auth);
        if (auth_info) {
            struct iovec parts[2];
            parts[0].iov_len = out->authorization_protocol_name_len = auth_info->namelen;
            parts[0].iov_base = auth_info->name;
            parts[1].iov_len = out->authorization_protocol_data_len = auth_info->datalen;
            parts[1].iov_base = auth_info->data;
            XCBWrite(c->handle, parts, 2);
        }
    }
    if(XCBFlushLocked(c->handle) <= 0)
        goto error;

    /* Read the server response */
    c->setup = malloc(sizeof(XCBConnSetupGenericRep));
    assert(c->setup);

    if(XCBRead(c->handle, c->setup, sizeof(XCBConnSetupGenericRep)) != sizeof(XCBConnSetupGenericRep))
        goto error;

    c->setup = realloc(c->setup, c->setup->length * 4 + sizeof(XCBConnSetupGenericRep));
    assert(c->setup);

    if(XCBRead(c->handle, (char *) c->setup + sizeof(XCBConnSetupGenericRep), c->setup->length * 4) != c->setup->length * 4)
        goto error;

    /* 0 = failed, 2 = authenticate, 1 = success */
    switch(c->setup->status)
    {
    case 0: /* failed */
        {
            XCBConnSetupFailedRep *setup = (XCBConnSetupFailedRep *) c->setup;
            write(STDERR_FILENO, XCBConnSetupFailedRepReason(setup), XCBConnSetupFailedRepReasonLength(setup));
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/

    case 2: /* authenticate */
        {
            XCBConnSetupAuthenticateRep *setup = (XCBConnSetupAuthenticateRep *) c->setup;
            write(STDERR_FILENO, XCBConnSetupAuthenticateRepReason(setup), XCBConnSetupAuthenticateRepReasonLength(setup));
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/
    }

    XCBIOSetReader(c->handle, XCBReadPacket, c);
    pthread_mutex_unlock(&c->locked);
    return c;

error:
    XCBDisconnect(c);
    return 0;
}

XCBConnection *XCBConnectBasic()
{
    int fd, display = 0, screen = 0;
    char *host;
    XCBConnection *c;

    if(!XCBParseDisplay(0, &host, &display, &screen))
    {
        fprintf(stderr, "Invalid DISPLAY\n");
        abort();
    }
    fd = XCBOpen(host, display);
    free(host);
    if(fd == -1)
    {
        perror("XCBOpen");
        abort();
    }

    c = XCBConnect(fd, XCBNextNonce());
    if(!c)
    {
        perror("XCBConnect");
        abort();
    }

    return c;
}

int XCBParseDisplay(const char *name, char **host, int *display, int *screen)
{
    char *colon;
    if(!name || !*name)
        name = getenv("DISPLAY");
    if(!name)
        return 0;
    *host = strdup(name);
    if(!*host)
        return 0;
    colon = strchr(*host, ':');
    if(!colon)
    {
        free(*host);
        *host = 0;
        return 0;
    }
    *colon = '\0';
    ++colon;
    return sscanf(colon, "%d.%d", display, screen);
}

int XCBSync(XCBConnection *c, XCBGenericError **e)
{
    XCBGetInputFocusRep *reply = XCBGetInputFocusReply(c, XCBGetInputFocus(c), e);
    free(reply);
    return (reply != 0);
}

static int match_extension_string(const void *name, const void *data)
{
    return (((XCBExtensionRecord *) data)->name == name);
}

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBQueryExtensionCached(XCBConnection *c, const char *name, XCBGenericError **e)
{
    XCBExtensionRecord *data = 0;
    if(e)
        *e = 0;
    pthread_mutex_lock(&c->locked);

    data = (XCBExtensionRecord *) XCBListRemove(c->extension_cache, match_extension_string, name);

    if(!data)
    {
	/* cache miss: query the server */
	pthread_mutex_unlock(&c->locked);
	data = (XCBExtensionRecord *) malloc((1) * sizeof(XCBExtensionRecord));
	assert(data);
	data->name = (char *) name;
	data->info = XCBQueryExtensionReply(c, XCBQueryExtension(c, strlen(name), name), e);
	pthread_mutex_lock(&c->locked);
    }

    XCBListInsert(c->extension_cache, data);

    pthread_mutex_unlock(&c->locked);
    return data->info;
}

static void free_extension_record(XCBExtensionRecord *data)
{
    free(data->info);
    free(data);
}

void XCBDisconnect(XCBConnection *c)
{
    if(!c)
        return;
    XCBListDelete(c->reply_data, (XCBListFreeFunc) free_reply_data);
    XCBListDelete(c->event_data, free);
    XCBListDelete(c->extension_cache, (XCBListFreeFunc) free_extension_record);
    free(c->handle);
    free(c->setup);
    free(c);
}
