/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <assert.h>
#include <X11/XCB/xcb_conn.h>

#include <sys/types.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <X11/Xauth.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

#undef USENONBLOCKING

#define XA1 "XDM-AUTHORIZATION-1"
#define MC1 "MIT-MAGIC-COOKIE-1"
static char *authtypes[] = { /* XA1, */ MC1 };
static int authtypelens[] = { /* sizeof(XA1)-1, */ sizeof(MC1)-1 };

void *XCBReplyDataAfterIter(XCBReplyDataIter i)
{
    while(i.rem > 0)
        XCBReplyDataNext(&i);
    return (void *) i.data;
}

void *XCBAuthInfoAfterIter(XCBAuthInfoIter i)
{
    while(i.rem > 0)
        XCBAuthInfoNext(&i);
    return (void *) i.data;
}

void *XCBConnectionAfterIter(XCBConnectionIter i)
{
    while(i.rem > 0)
        XCBConnectionNext(&i);
    return (void *) i.data;
}

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

static int match_reply_seqnum16(const void *seqnum, const void *data)
{
    return ((CARD16) ((XCBReplyData *) data)->seqnum == (CARD16) *(int *) seqnum);
}

static int match_reply_seqnum32(const void *seqnum, const void *data)
{
    return (((XCBReplyData *) data)->seqnum == *(int *) seqnum);
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
    {
        length += genrep.length * 4;
        if(XCBIOReadable(h) < length)
            return 0;
    }

    buf = (unsigned char *) malloc((length) * sizeof(unsigned char));
    assert(buf);
    ret = XCBRead(h, buf, length);

    /* Only compare the low 16 bits of the seqnum of the packet. */
    if(!(buf[0] & ~1)) /* reply or error packet */
        rep = (XCBReplyData *) XCBListFind(c->reply_data, match_reply_seqnum16, &((XCBGenericRep *) buf)->seqnum);

    if(buf[0] == 1 && !rep) /* I see no reply record here, but I need one. */
    {
        fprintf(stderr, "No reply record found for reply %d.\n", ((XCBGenericRep *) buf)->seqnum);
        free(buf);
        return -1;
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

void *XCBWaitSeqnum(XCBConnection *c, unsigned int seqnum, XCBGenericEvent **e)
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
            *e = (XCBGenericEvent *) cur->data;
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
    fprintf(stderr, "Leaving XCBWaitEvent, event type %d\n", ret->response_type);
#endif

    return ret;
}

XCBGenericEvent *XCBPollEvent(XCBConnection *c)
{
    XCBFillBufferLocked(c->handle);
    /* XCBListRemoveHead returns 0 on empty list. */
    return (XCBGenericEvent *) XCBListRemoveHead(c->event_data);
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

XCBAuthInfo *XCBGetAuthInfo(int fd, int nonce, XCBAuthInfo *info)
{
    /* code adapted from Xlib/ConnDis.c, xtrans/Xtranssocket.c,
       xtrans/Xtransutils.c */
    char sockbuf[sizeof(struct sockaddr) + MAXPATHLEN];
    int socknamelen = sizeof(sockbuf);   /* need extra space */
    struct sockaddr *sockname = (struct sockaddr *) &sockbuf;
    char *addr;
    int addrlen;
    unsigned short family;
    char hostnamebuf[256];   /* big enough for max hostname */
    char dispbuf[40];   /* big enough to hold more than 2^64 base 10 */
    char *display;
    Xauth *authptr = 0;

    if (getpeername(fd, (struct sockaddr *) sockname, &socknamelen) == -1)
    	return 0;  /* can only authenticate sockets */
    family = FamilyLocal; /* 256 */
    if (sockname->sa_family == AF_INET) {
        struct sockaddr_in *si = (struct sockaddr_in *) sockname;
	assert(sizeof(*si) == socknamelen);
        addr = (char *) &si->sin_addr;
        addrlen = 4;
        family = FamilyInternet; /* 0 */
        if (ntohl(si->sin_addr.s_addr) == 0x7f000001)
	    family = FamilyLocal; /* 256 */
	(void) sprintf(dispbuf, "%d", ntohs(si->sin_port) - X_TCP_PORT);
        display = dispbuf;
    } else if (sockname->sa_family == AF_UNIX) {
        struct sockaddr_un *su = (struct sockaddr_un *) sockname;
	assert(sizeof(*su) >= socknamelen);
        display = strrchr(su->sun_path, 'X');
	if (display == 0)
	    return 0;   /* sockname is mangled somehow */
        display++;
    } else {
    	return 0;   /* cannot authenticate this family */
    }
    if (family == FamilyLocal) {
    	if (gethostname(hostnamebuf, sizeof(hostnamebuf)) == -1)
	    return 0;   /* do not know own hostname */
	addr = hostnamebuf;
        addrlen = strlen(addr);
    }
    authptr = XauGetBestAuthByAddr (family,
                                    (unsigned short) addrlen, addr,
                                    (unsigned short) strlen(display), display,
				    sizeof(authtypes)/sizeof(authtypes[0]),
				    authtypes, authtypelens);
    if (authptr == 0)
        return 0;   /* cannot find good auth data */
    if (sizeof(MC1)-1 == authptr->name_length &&
        !memcmp(MC1, authptr->name, authptr->name_length)) {
	(void)memcpy(info->name,
                     authptr->name,
                     authptr->name_length);
	info->namelen = authptr->name_length;
	(void)memcpy(info->data,
                     authptr->data,
                     authptr->data_length);
	info->datalen = authptr->data_length;
        XauDisposeAuth(authptr);
        return info;
    }
    if (sizeof(XA1)-1 == authptr->name_length &&
        !memcmp(XA1, authptr->name, authptr->name_length)) {
	int j;
	long now;

	(void)memcpy(info->name,
                     authptr->name,
                     authptr->name_length);
	info->namelen = authptr->name_length;
	for (j = 0; j < 8; j++)
            info->data[j] = authptr->data[j];
	XauDisposeAuth(authptr);
	if (sockname->sa_family == AF_INET) {
            struct sockaddr_in *si =
              (struct sockaddr_in *) sockname;
            (void)memcpy(info->data + j,
                         &si->sin_addr.s_addr,
                         sizeof(si->sin_addr.s_addr));
            j += sizeof(si->sin_addr.s_addr);
            (void)memcpy(info->data + j,
                         &si->sin_port,
                         sizeof(si->sin_port));
            j += sizeof(si->sin_port);
        } else if (sockname->sa_family == AF_UNIX) {
            long fakeaddr = htonl(0xffffffff - nonce);
	    short fakeport = htons(getpid());
            (void)memcpy(info->data + j, &fakeaddr, sizeof(long));
            j += sizeof(long);
            (void)memcpy(info->data + j, &fakeport, sizeof(short));
            j += sizeof(short);
        } else {
            return 0;   /* do not know how to build this */
        }
        (void)time(&now);
        now = htonl(now);
        memcpy(info->data + j, &now, sizeof(long));
	j += sizeof(long);
        while (j < 192 / 8)
            info->data[j++] = 0;
	info->datalen = j;
        return info;
    }
    XauDisposeAuth(authptr);
    return 0;   /* Unknown authorization type */
}

XCBConnection *XCBConnect(int fd, int screen, int nonce)
{
    XCBAuthInfo info, *infop;
    infop = XCBGetAuthInfo(fd, nonce, &info);
    return XCBConnectAuth(fd, infop);
}

XCBConnection *XCBConnectAuth(int fd, XCBAuthInfo *auth_info)
{
    XCBConnection* c;

    c = (XCBConnection *) malloc((1) * sizeof(XCBConnection));
    assert(c);

    pthread_mutex_init(&c->locked, 0);
    pthread_mutex_lock(&c->locked);

    c->handle = XCBIOFdOpen(fd, &c->locked);
    if(!c->handle)
        goto error;

    c->reply_data = XCBListNew();
    c->event_data = XCBListNew();
    c->extension_cache = XCBListNew();

    c->last_request = 0;
    c->seqnum = 0;
    c->seqnum_written = 0;
    c->last_xid = 0;

    /* Write the connection setup request. */
    {
        XCBConnSetupReq *out = (XCBConnSetupReq *) XCBAllocOut(c->handle, XCB_CEIL(sizeof(XCBConnSetupReq)));

        /* B = 0x42 = MSB first, l = 0x6c = LSB first */
        out->byte_order = 0x6c;
        out->protocol_major_version = X_PROTOCOL;
        out->protocol_minor_version = X_PROTOCOL_REVISION;
        out->authorization_protocol_name_len = 0;
        out->authorization_protocol_data_len = 0;
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
            write(STDERR_FILENO, XCBConnSetupFailedRepreason(setup), XCBConnSetupFailedRepreasonLength(setup));
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/

    case 2: /* authenticate */
        {
            XCBConnSetupAuthenticateRep *setup = (XCBConnSetupAuthenticateRep *) c->setup;
            write(STDERR_FILENO, XCBConnSetupAuthenticateRepreason(setup), XCBConnSetupAuthenticateRepreasonLength(setup));
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/
    }

    XCBIOSetReader(c->handle, XCBReadPacket, c);
    pthread_mutex_unlock(&c->locked);
    return c;

error:
    if(c)
        free(c->handle);
    free(c);
    return 0;
}

XCBConnection *XCBConnectBasic()
{
    static int nonce = 0;
    static pthread_mutex_t nonce_mutex = PTHREAD_MUTEX_INITIALIZER;
    int fd, screen;
    XCBConnection *c;
    fd = XCBOpen(getenv("DISPLAY"), &screen);
    if(fd == -1)
    {
        perror("XCBOpen");
        abort();
    }

    pthread_mutex_lock(&nonce_mutex);
    c = XCBConnect(fd, screen, nonce);
    nonce++;
    pthread_mutex_unlock(&nonce_mutex);
    if(!c)
    {
        perror("XCBConnect");
        abort();
    }

    return c;
}