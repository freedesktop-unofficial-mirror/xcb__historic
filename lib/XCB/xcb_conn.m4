XCBGEN(xcb_conn, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
SOURCEONLY(`
REQUIRE(sys/types)
REQUIRE(sys/param)
REQUIRE(sys/socket)
REQUIRE(sys/fcntl)
REQUIRE(sys/un)
REQUIRE(netinet/in)
REQUIRE(X11/Xauth)
REQUIRE(netdb)
REQUIRE(stdio)
REQUIRE(unistd)
REQUIRE(stdlib)
REQUIRE(errno)

CPPUNDEF(`USENONBLOCKING')
')HEADERONLY(`dnl
REQUIRE(xcb_list)
REQUIRE(xcb_types)
REQUIRE(xcb_io)
REQUIRE(sys/uio)
REQUIRE(pthread)

/* Pre-defined constants */

COMMENT(current protocol version)
CONSTANT(CARD16, `X_PROTOCOL', `11')

COMMENT(current minor version)
CONSTANT(CARD16, `X_PROTOCOL_REVISION', `0')

/* Maximum size of authentication names and data */
CPPDEFINE(`AUTHNAME_MAX',`256')
CPPDEFINE(`AUTHDATA_MAX',`256')

STRUCT(XCBReplyData, `
    FIELD(int, `pending')
    FIELD(int, `error')
    FIELD(int, `seqnum')
    POINTERFIELD(void, `data')
')

STRUCT(XCBAuthInfo, `
    FIELD(`int', `namelen')
    FIELD(`char', `name[AUTHNAME_MAX]')
    FIELD(`int', `datalen')
    FIELD(`char', `data[AUTHDATA_MAX]')
')

STRUCT(XCBDepth, `
    POINTERFIELD(DEPTH, `data')
    POINTERFIELD(VISUALTYPE, `visuals')
')

STRUCT(XCBScreen, `
    POINTERFIELD(SCREEN, `data')
    POINTERFIELD(XCBDepth, `depths')
')

STRUCT(XCBConnection, `
    FIELD(pthread_mutex_t, `locked')

    POINTERFIELD(XCBIOHandle, `handle')

    POINTERFIELD(XCBList, `reply_data')
    POINTERFIELD(XCBList, `event_data')
    POINTERFIELD(XCBList, `extension_cache')

    POINTERFIELD(void, `last_request')
    FIELD(unsigned int, `seqnum')
    FIELD(unsigned int, `seqnum_written')
    FIELD(CARD32, `last_xid')

    POINTERFIELD(char, `vendor')
    POINTERFIELD(FORMAT, `pixmapFormats')
    POINTERFIELD(XCBScreen, `roots')
    POINTERFIELD(XCBConnSetupSuccessRep, `setup')
')
')dnl end HEADERONLY

/* Utility functions */

FUNCTION(`int XCBOnes', `unsigned long mask', `
    register unsigned long y;
    y = (mask >> 1) & 033333333333;
    y = mask - y - ((y >> 1) & 033333333333);
    return ((y + (y >> 3)) & 030707070707) % 077;
')
_C
FUNCTION(`CARD32 XCBGenerateID', `XCBConnection *c', `
    CARD32 ret;
    pthread_mutex_lock(&c->locked);
    ret = c->last_xid | c->setup->resource_id_base;
    c->last_xid += c->setup->resource_id_mask & -(c->setup->resource_id_mask);
    pthread_mutex_unlock(&c->locked);
    return ret;
')

/* Specific list implementations */

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`void XCBAddReplyData', `XCBConnection *c, int seqnum', `
    XCBReplyData *data;
ALLOC(XCBReplyData, `data', 1)

    data->pending = 0;
    data->error = 0;
    data->seqnum = seqnum;
    data->data = 0;

    XCBListAppend(c->reply_data, data);
')

STATICFUNCTION(`int match_reply_seqnum16', `const void *seqnum, const void *data', `
    return ((CARD16) ((XCBReplyData *) data)->seqnum == (CARD16) *(int *) seqnum);
')
_C
STATICFUNCTION(`int match_reply_seqnum32', `const void *seqnum, const void *data', `
    return (((XCBReplyData *) data)->seqnum == *(int *) seqnum);
')
_C
STATICFUNCTION(`int XCBReadPacket', `void *readerdata, XCBIOHandle *h', `
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

ALLOC(unsigned char, buf, length)
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
')
_C
FUNCTION(`void *XCBWaitSeqnum', `XCBConnection *c, unsigned int seqnum, XCBGenericEvent **e', `
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
')
_C
FUNCTION(`XCBGenericEvent *XCBWaitEvent', `XCBConnection *c', `
    XCBGenericEvent *ret;

#if XCBTRACEEVENT
    fprintf(stderr, "Entering XCBWaitEvent\n");
#endif

    pthread_mutex_lock(&c->locked);
    while(XCBListIsEmpty(c->event_data))
        if(XCBWait(c->handle, /*should_write*/ 0) <= 0)
            break;
    ret = (XCBGenericEvent *) XCBListRemoveHead(c->event_data);

    pthread_mutex_unlock(&c->locked);

#if XCBTRACEEVENT
    fprintf(stderr, "Leaving XCBWaitEvent, event type %d\n", ret->response_type);
#endif

    return ret;
')
_C
FUNCTION(`int XCBFlush', `XCBConnection *c', `
    int ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBFlushLocked(c->handle);
    c->last_request = 0;
    c->seqnum_written = c->seqnum;
    pthread_mutex_unlock(&c->locked);
    return ret;
')

define(`MC1',`"MIT-MAGIC-COOKIE-1"')dnl
define(`XA1',`"XDM-AUTHORIZATION-1"')dnl
_C static char *authtypes[] = { XA1, MC1 };
_C static int authtypelens[] = { sizeof(XA1)-1, sizeof(MC1)-1 };
FUNCTION(`XCBAuthInfo *XCBGetAuthInfo',
         `int fd, int nonce, XCBAuthInfo *info', `
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
        display = strrchr(su->sun_path, CHAR(`X'));
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
')
_C
FUNCTION(`XCBConnection *XCBConnect', `int fd, int screen, int nonce', `
    XCBAuthInfo info, *infop;
    infop = XCBGetAuthInfo(fd, nonce, &info);
    return XCBConnectAuth(fd, infop);
')
_C
FUNCTION(`XCBConnection *XCBConnectAuth', `int fd, XCBAuthInfo *auth_info', `
    XCBConnection* c;

ALLOC(XCBConnection, c, 1)

    pthread_mutex_init(&c->locked, 0);
    pthread_mutex_lock(&c->locked);

    c->handle = XCBIOFdOpen(fd, &c->locked, XCBReadPacket, c);
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
            write(STDERR_FILENO, setup + 1, setup->reason_len);
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/

    case 2: /* authenticate */
        {
            XCBConnSetupAuthenticateRep *setup = (XCBConnSetupAuthenticateRep *) c->setup;
            write(STDERR_FILENO, setup + 1, setup->length * 4);
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/
    }

    /* Set up a collection of convenience pointers. */
    c->vendor = (char *) (c->setup + 1);
    c->pixmapFormats = (FORMAT *) (c->vendor + XCB_CEIL(c->setup->vendor_len));

    {INDENT()
        SCREEN *root;
        DEPTH *depth;
        VISUALTYPE *visual;
        int i, j;

ALLOC(XCBScreen, c->roots, c->setup->roots_len)

        root = (SCREEN *) (c->pixmapFormats + c->setup->pixmap_formats_len);
        for(i = 0; i < c->setup->roots_len; ++i)
        {INDENT()
            c->roots[i].data = root;
ALLOC(XCBDepth, c->roots[i].depths, root->allowed_depths_len)

            depth = (DEPTH *) (root + 1);
            for(j = 0; j < root->allowed_depths_len; ++j)
            {
                c->roots[i].depths[j].data = depth;
                visual = (VISUALTYPE *) (depth + 1);
                c->roots[i].depths[j].visuals = visual;
                depth = (DEPTH *) (visual + depth->visuals_len);
            }
            root = (SCREEN *) depth;
        }UNINDENT()
    }UNINDENT()

    pthread_mutex_unlock(&c->locked);
    return c;

error:
    if(c)
        free(c->handle);
    free(c);
    return 0;
')
_C
FUNCTION(`XCBConnection *XCBConnectBasic', `', `
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
')
ENDXCBGEN
