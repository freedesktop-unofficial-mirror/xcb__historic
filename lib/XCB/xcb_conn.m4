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
REQUIRE(xcb_types)
REQUIRE(sys/uio)
REQUIRE(pthread)

/* Number of bytes needed to pad E bytes to a 4-byte boundary. */
CPPDEFINE(`XCB_PAD(E)', `((4-((E)%4))%4)')

/* Index of nearest 4-byte boundary following E. */
CPPDEFINE(`XCB_CEIL(E)', `(((E)+3)&~3)')

/* Maximum size of authentication names and data */
CPPDEFINE(`AUTHNAME_MAX',`256')
CPPDEFINE(`AUTHDATA_MAX',`256')

STRUCT(XCB_ListNode, `
    POINTERFIELD(struct XCB_ListNode, `next')
    POINTERFIELD(void, `data')
')
STRUCT(XCB_List, `
    POINTERFIELD(XCB_ListNode, `head')
    POINTERFIELD(XCB_ListNode, `tail')
')

STRUCT(XCB_Reply_Data, `
    FIELD(int, `pending')
    FIELD(int, `error')
    FIELD(int, `seqnum')
    POINTERFIELD(void, `data')
')

PACKETSTRUCT(Generic, `Rep', `')
PACKETSTRUCT(Generic, `Event', `')
PACKETSTRUCT(Generic, `Error', `')
typedef XCB_Generic_Event XCB_Event; /* deprecated name */

STRUCT(XCB_Auth_Info, `
    FIELD(`int', `namelen')
    FIELD(`char', `name[AUTHNAME_MAX]')
    FIELD(`int', `datalen')
    FIELD(`char', `data[AUTHDATA_MAX]')
')

STRUCT(XCB_Depth, `
    POINTERFIELD(DEPTH, `data')
    POINTERFIELD(VISUALTYPE, `visuals')
')

STRUCT(XCB_Screen, `
    POINTERFIELD(SCREEN, `data')
    POINTERFIELD(XCB_Depth, `depths')
')

STRUCT(XCB_Connection, `
    FIELD(int, `fd')
    FIELD(pthread_mutex_t, `locked')
    FIELD(pthread_cond_t, `waiting_threads')
    FIELD(int, `reading')
    FIELD(int, `writing')

    FIELD(XCB_List, `reply_data')
    FIELD(XCB_List, `event_data')
    FIELD(XCB_List, `extension_cache')

    ARRAYFIELD(CARD8, `outqueue', 4096)
    FIELD(int, `n_outqueue')
    POINTERFIELD(struct iovec, `outvec')
    FIELD(int, `n_outvec')

    FIELD(int, `seqnum')
    FIELD(CARD32, `last_xid')

    dnl FIELD(XCB_Atom_Dictionary, `atoms')

    POINTERFIELD(char, `vendor')
    POINTERFIELD(FORMAT, `pixmapFormats')
    POINTERFIELD(XCB_Screen, `roots')
    POINTERFIELD(XCB_ConnSetup_Success_Rep, `setup')
')

COOKIETYPE(`void')
')dnl end HEADERONLY

/* Utility functions */

FUNCTION(`int XCB_Ones', `unsigned long mask', `
    register unsigned long y;
    y = (mask >> 1) & 033333333333;
    y = mask - y - ((y >> 1) & 033333333333);
    return ((y + (y >> 3)) & 030707070707) % 077;
')
_C
FUNCTION(`CARD32 XCB_Generate_ID', `XCB_Connection *c', `
    CARD32 ret;
    pthread_mutex_lock(&c->locked);
    ret = c->last_xid | c->setup->resource_id_base;
    c->last_xid += c->setup->resource_id_mask & -(c->setup->resource_id_mask);
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`void *XCB_Alloc_Out', `XCB_Connection *c, int size', `
    void *out;
    if(c->n_outvec || c->n_outqueue + size > sizeof(c->outqueue))
    {
        int ret = XCB_Flush_locked(c);
        assert(ret > 0);
    }

    out = c->outqueue + c->n_outqueue;
    c->n_outqueue += size;
    assert(c->n_outqueue <= sizeof(c->outqueue));
    return out;
')

/* Linked list functions */

FUNCTION(`void XCB_List_init', `XCB_List *list', `
    list->head = list->tail = 0;
')
_C
FUNCTION(`void XCB_List_insert', `XCB_List *list, void *data', `
    XCB_ListNode *node;
ALLOC(XCB_ListNode, `node', 1)
    node->data = data;

    node->next = list->head;
    list->head = node;
    if(!list->tail)
        list->tail = node;
')
_C
FUNCTION(`void XCB_List_append', `XCB_List *list, void *data', `
    XCB_ListNode *node;
ALLOC(XCB_ListNode, `node', 1)
    node->data = data;
    node->next = 0;

    if(list->tail)
        list->tail->next = node;
    else
        list->head = node;

    list->tail = node;
')
_C
FUNCTION(`void *XCB_List_remove_head', `XCB_List *list', `
    void *ret;
    XCB_ListNode *tmp = list->head;
    if(!tmp)
        return 0;
    ret = tmp->data;
    list->head = tmp->next;
    if(!list->head)
        list->tail = 0;
    free(tmp);
    return ret;
')
_C
FUNCTION(`void *XCB_List_remove', `XCB_List *list, int (*cmp)(const void *, const void *), const void *data', `
    XCB_ListNode *prev = 0, *cur = list->head;
    void *tmp;

    while(cur)
    {
        if(cmp(data, cur->data))
            break;
        prev = cur;
        cur = cur->next;
    }
    if(!cur)
        return 0;

    if(prev)
        prev->next = cur->next;
    else
        list->head = cur->next;
    if(!cur->next)
        list->tail = prev;

    tmp = cur->data;
    free(cur);
    return tmp;
')
_C
FUNCTION(`void *XCB_List_find', `XCB_List *list, int (*cmp)(const void *, const void *), const void *data', `
    XCB_ListNode *cur = list->head;
    while(cur)
    {
        if(cmp(data, cur->data))
            return cur->data;
        cur = cur->next;
    }
    return 0;
')
_C
FUNCTION(`int XCB_List_is_empty', `XCB_List *list', `
    return (list->head == 0);
')

/* Specific list implementations */

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`void XCB_Add_Reply_Data', `XCB_Connection *c, int seqnum', `
    XCB_Reply_Data *data;
ALLOC(XCB_Reply_Data, `data', 1)

    data->pending = 0;
    data->error = 0;
    data->seqnum = seqnum;
    data->data = 0;

    XCB_List_append(&c->reply_data, data);
')

FUNCTION(`int XCB_EventQueueIsEmpty', `XCB_Connection *c', `
    return XCB_List_is_empty(&c->event_data);
')
SOURCEONLY(`
/* read(2)/write(2) wrapper functions */

STATICFUNCTION(`int XCB_read_internal', `XCB_Connection *c, void *buf, int nread',`
#ifdef USENONBLOCKING
    int count = 0;
    int n;
    fd_set rfds;
    FD_ZERO(&rfds);
    FD_SET(c->fd, &rfds);
    while(nread > 0)
    {
        n = read(c->fd, buf, nread);
        if(n == -1)
        {
            if (errno != EAGAIN)
                return -1;
            n = 0;
        }
        if(n == 0)
        {
            if(select(c->fd + 1, &rfds, 0, 0, 0) == -1)
                return -1;
        }
        nread -= n;
        buf += n;
        count += n;
    }
    return count;
#else
    return read(c->fd, buf, nread);
#endif
')

STATICFUNCTION(`int XCB_write_internal', `XCB_Connection *c, void *buf, int nwrite',`
#ifdef USENONBLOCKING
    int count = 0;
    int n;
    fd_set wfds;
    FD_ZERO(&wfds);
    FD_SET(c->fd, &wfds);
    while(nwrite > 0)
    {
        n = write(c->fd, buf, nwrite);
        if(n == -1)
        {
            if (errno != EAGAIN)
                return -1;
            n = 0;
        }
        if(n == 0)
        {
            if(select(c->fd + 1, 0, &wfds, 0, 0) == -1)
                return -1;
        }
        nwrite -= n;
        buf += n;
        count += n;
    }
    return count;
#else
    return write(c->fd, buf, nwrite);
#endif
')

STATICFUNCTION(`int match_reply_seqnum16', `const void *seqnum, const void *data', `
    return ((CARD16) ((XCB_Reply_Data *) data)->seqnum == (CARD16) *(int *) seqnum);
')

STATICFUNCTION(`int match_reply_seqnum32', `const void *seqnum, const void *data', `
    return (((XCB_Reply_Data *) data)->seqnum == *(int *) seqnum);
')

STATICFUNCTION(`int XCB_read_packet', `XCB_Connection *c', `
    int ret;
    XCB_Reply_Data *rep = 0;
    unsigned char *buf;
ALLOC(unsigned char, buf, 32)

    ret = XCB_read_internal(c, buf, 32);
    if(ret != 32)
        return (ret <= 0) ? ret : -1;

    if(buf[0] == 1) /* get the payload for a reply packet */
    {INDENT()
        CARD32 length = ((XCB_Generic_Rep *) buf)->length;
        if(length)
        {INDENT()
REALLOC(unsigned char, buf, 32 + length * 4)

            ret = XCB_read_internal(c, buf + 32, length * 4);
            if(ret != length * 4)
                return (ret <= 0) ? ret : -1;
        }UNINDENT()
    }UNINDENT()

    /* Only compare the low 16 bits of the seqnum of the packet. */
    if(!(buf[0] & ~1)) /* reply or error packet */
        rep = (XCB_Reply_Data *) XCB_List_find(&c->reply_data, match_reply_seqnum16, &((XCB_Generic_Rep *) buf)->seqnum);

    if(buf[0] == 1 && !rep) /* I see no reply record here, but I need one. */
    {
        fprintf(stderr, "No reply record found for reply %d.\n", ((XCB_Generic_Rep *) buf)->seqnum);
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
        XCB_List_append(&c->event_data, (XCB_Event *) buf);

    return 1; /* I have something for you... */
')

STATICFUNCTION(`int XCB_write_buffer', `XCB_Connection *c', `
    int ret;
    ret = XCB_write_internal(c, c->outqueue, c->n_outqueue);
    if(ret != c->n_outqueue)
        return (ret <= 0) ? ret : -1;

    c->n_outqueue = 0;
    if(c->n_outvec)
    {
        assert(0);  /* FIXME: outvec support turned off */
        writev(c->fd, c->outvec, c->n_outvec);
        c->n_outvec = 0;
    }

    return 1;
')

STATICFUNCTION(`int XCB_Wait', `XCB_Connection *c, const int should_write', `
    int ret = 1, should_read;
    fd_set rfds, wfds;

    /* If the thing I should be doing is already being done, wait for it. */
    if(should_write ? c->writing : c->reading)
    {
        pthread_cond_wait(&c->waiting_threads, &c->locked);
        return 1;
    }

    /* If anyone gets here, somebody needs to be reading.
     * Maybe it should be me, but only if it is nobody else. */
    should_read = !c->reading;
    if(should_read)
        c->reading = 1;
    if(should_write)
        c->writing = 1;

    FD_ZERO(&rfds);
    FD_ZERO(&wfds);

    if(should_read)
        FD_SET(c->fd, &rfds);
    if(should_write)
        FD_SET(c->fd, &wfds);

    pthread_mutex_unlock(&c->locked);
    ret = select(c->fd + 1, &rfds, &wfds, 0, 0);
    pthread_mutex_lock(&c->locked);

    if(ret <= 0) /* error: select failed */
        goto done;

    if(FD_ISSET(c->fd, &rfds))
        if((ret = XCB_read_packet(c)) <= 0)
            goto done;

    if(FD_ISSET(c->fd, &wfds))
        if((ret = XCB_write_buffer(c)) <= 0)
            goto done;

done:
    /* Wake up anyone affected by whatever I just did. */
    pthread_cond_broadcast(&c->waiting_threads);

    if(should_write)
        c->writing = 0;
    if(should_read)
        c->reading = 0;

    return ret;
')
')dnl end SOURCEONLY

FUNCTION(`void *XCB_Wait_Seqnum', `XCB_Connection *c, int seqnum, XCB_Event **e', `
    void *ret = 0;
    XCB_Reply_Data *cur;
    if(e)
        *e = 0;

    pthread_mutex_lock(&c->locked);
    /* Compare the sequence number as a full int. */
    cur = (XCB_Reply_Data *) XCB_List_find(&c->reply_data, match_reply_seqnum32, &seqnum);

    if(!cur || cur->pending || XCB_Flush_locked(c) <= 0) /* error */
        goto done;

    ++cur->pending;

    while(!cur->data)
        if(XCB_Wait(c, /*should_write*/ 0) <= 0)
        {
            /* Do not remove the reply record on I/O error. */
            --cur->pending;
            goto done;
        }

    /* No need to update pending flag - about to delete cur anyway. */

    if(cur->error)
    {
        if(!e)
            XCB_List_append(&c->event_data, (XCB_Event *) cur->data);
        else
            *e = (XCB_Event *) cur->data;
    }
    else
        ret = cur->data;

    /* Compare the sequence number as a full int. */
    XCB_List_remove(&c->reply_data, match_reply_seqnum32, &seqnum);
    free(cur);

done:
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`XCB_Event *XCB_Wait_Event', `XCB_Connection *c', `
    void *ret;

    pthread_mutex_lock(&c->locked);
    while(XCB_List_is_empty(&c->event_data))
        if(XCB_Wait(c, /*should_write*/ 0) <= 0)
            break;
    ret = XCB_List_remove_head(&c->event_data);

    pthread_mutex_unlock(&c->locked);
    return (XCB_Event *) ret;
')
_C
FUNCTION(`int XCB_Flush', `XCB_Connection *c', `
    int ret;
    pthread_mutex_lock(&c->locked);
    ret = XCB_Flush_locked(c);
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`int XCB_Flush_locked', `XCB_Connection *c', `
    int ret = 1;
    while(ret > 0 && c->n_outqueue)
        ret = XCB_Wait(c, /*should_write*/ 1);
    return ret;
')

/* PRE: c is locked */
FUNCTION(`void XCB_Write', `XCB_Connection *c, struct iovec *vector, size_t count', `
    int i, len;

    for(i = 0, len = 0; i < count; ++i)
        len += vector[i].iov_len;

    /* Is the queue about to overflow? */
    if(c->n_outqueue + len < sizeof(c->outqueue))
    {
        /* No, this will fit. */
        for(i = 0; i < count; ++i)
        {
            memcpy(c->outqueue + c->n_outqueue, vector[i].iov_base, vector[i].iov_len);
            c->n_outqueue += vector[i].iov_len;
        }
        i = XCB_Flush_locked(c);
        assert(i > 0);
        return;
    }

    assert(0);  /* FIXME: turning off outvec support */
    c->outvec = vector;
    c->n_outvec = count;
    i = XCB_Flush_locked(c);
    assert(i > 0);
')

FUNCTION(`int XCB_Open', `const char *display, int *screen', `
    int fd = -1;
    char *buf, *colon, *dot;

    if(!display)
    {
        printf("Error: display not set\n");
        return -1;
    }

ALLOC(char, buf, strlen(display) + 1)
    strcpy(buf, display);

dnl quote in C char constants causes confusion
    colon = strchr(buf, CHAR(`:'));
    if(!colon)
    {
        printf("Error: invalid display: \"%s\"\n", buf);
        return -1;
    }
    *colon = CHAR(`\0');
    ++colon;

    dot = strchr(colon, CHAR(`.'));
    if(dot)
    {
        *dot = CHAR(`\0');
        ++dot;
        if(screen)
            *screen = atoi(dot);
    }
    else
        if(screen)
            *screen = 0;

    if(*buf)
    {
        /* display specifies TCP */
        unsigned short port = X_TCP_PORT + atoi(colon);
        fd = XCB_Open_TCP(buf, port);
    }
    else
    {
        /* display specifies Unix socket */
        char file[] = "/tmp/.X11-unix/X\0\0";
        strcat(file, colon);
        fd = XCB_Open_Unix(file);
    }

    free(buf);
    return fd;
')
_C
FUNCTION(`int XCB_Open_TCP', `const char *host, unsigned short port', `
    int fd;
    struct sockaddr_in addr = { AF_INET, htons(port) };
    /* CHECKME: never free return value of gethostbyname, right? */
    struct hostent *hostaddr = gethostbyname(host);
    assert(hostaddr);
    memcpy(&addr.sin_addr, hostaddr->h_addr_list[0], sizeof(addr.sin_addr));

    fd = socket(PF_INET, SOCK_STREAM, 0);
    assert(fd != -1);
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
')
_C
FUNCTION(`int XCB_Open_Unix', `const char *file', `
    int fd;
    struct sockaddr_un addr = { AF_UNIX };
    strcpy(addr.sun_path, file);

    fd = socket(PF_UNIX, SOCK_STREAM, 0);
    assert(fd != -1);
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
')
_C
define(`MC1',`"MIT-MAGIC-COOKIE-1"')dnl
define(`XA1',`"XDM-AUTHORIZATION-1"')dnl
_C static char *authtypes[] = { XA1, MC1 };
_C static int authtypelens[] = { sizeof(XA1)-1, sizeof(MC1)-1 };
FUNCTION(`XCB_Auth_Info *XCB_Get_Auth_Info',
         `int fd, int nonce, XCB_Auth_Info *info', `
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
FUNCTION(`XCB_Connection *XCB_Connect', `int fd, int screen, int nonce', `
    XCB_Auth_Info info, *infop;
    infop = XCB_Get_Auth_Info(fd, nonce, &info);
    return XCB_Connect_Auth(fd, infop);
')
_C
FUNCTION(`XCB_Connection *XCB_Connect_Auth',
         `int fd, XCB_Auth_Info *auth_info', `
    XCB_Connection* c;

ALLOC(XCB_Connection, c, 1)

#ifdef USENONBLOCKING
    if (fcntl(fd, F_SETFL, (long)O_NONBLOCK) == -1)
        return 0;
#endif
    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    pthread_cond_init(&c->waiting_threads, 0);
    c->reading = 0;
    c->writing = 0;

    XCB_List_init(&c->reply_data);
    XCB_List_init(&c->event_data);
    XCB_List_init(&c->extension_cache);

    /* c->outqueue does not need initialization */
    c->n_outqueue = 0;
    /* c->outvec does not need initialization */
    c->n_outvec = 0;

    c->seqnum = 0;
    c->last_xid = 0;

    /* Write the connection setup request. */
    {
        XCB_ConnSetup_Req *out = (XCB_ConnSetup_Req *) c->outqueue;
        c->n_outqueue = XCB_CEIL(sizeof(XCB_ConnSetup_Req));

        /* B = 0x42 = MSB first, l = 0x6c = LSB first */
        out->byte_order = 0x6c;
        out->protocol_major_version = X_PROTOCOL;
        out->protocol_minor_version = X_PROTOCOL_REVISION;
        out->authorization_protocol_name_len = 0;
        out->authorization_protocol_data_len = 0;
	if (auth_info) {
            out->authorization_protocol_name_len = auth_info->namelen;
	    memcpy(c->outqueue + c->n_outqueue,
		   auth_info->name,
                   out->authorization_protocol_name_len);
            c->n_outqueue += XCB_CEIL(out->authorization_protocol_name_len);
            out->authorization_protocol_data_len = auth_info->datalen;
            memcpy(c->outqueue + c->n_outqueue,
                   auth_info->data,
                   out->authorization_protocol_data_len);
            c->n_outqueue += XCB_CEIL(out->authorization_protocol_data_len);
        }
    }
    if(XCB_Flush(c) <= 0)
        goto error;

    /* Read the server response */
    c->setup = malloc(sizeof(XCB_ConnSetup_Generic_Rep));
    assert(c->setup);

    if(XCB_read_internal(c, c->setup, sizeof(XCB_ConnSetup_Generic_Rep)) != sizeof(XCB_ConnSetup_Generic_Rep))
        goto error;

    c->setup = realloc(c->setup, c->setup->length * 4 + sizeof(XCB_ConnSetup_Generic_Rep));
    assert(c->setup);

    if(XCB_read_internal(c, (char *) c->setup + sizeof(XCB_ConnSetup_Generic_Rep), c->setup->length * 4) != c->setup->length * 4)
        goto error;

    /* 0 = failed, 2 = authenticate, 1 = success */
    switch(c->setup->status)
    {
    case 0: /* failed */
        {
            XCB_ConnSetup_Failed_Rep *setup = (XCB_ConnSetup_Failed_Rep *) c->setup;
            write(STDERR_FILENO, setup + 1, setup->reason_len);
            write(STDERR_FILENO, "\n", sizeof("\n"));
            goto error;
        }
        /*NOTREACHED*/

    case 2: /* authenticate */
        {
            XCB_ConnSetup_Authenticate_Rep *setup = (XCB_ConnSetup_Authenticate_Rep *) c->setup;
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

ALLOC(XCB_Screen, c->roots, c->setup->roots_len)

        root = (SCREEN *) (c->pixmapFormats + c->setup->pixmap_formats_len);
        for(i = 0; i < c->setup->roots_len; ++i)
        {INDENT()
            c->roots[i].data = root;
ALLOC(XCB_Depth, c->roots[i].depths, root->allowed_depths_len)

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

    return c;

error:
    free(c);
    return 0;
')
_C
FUNCTION(`XCB_Connection *XCB_Connect_Basic', `', `
    static int nonce = 0;
    static pthread_mutex_t nonce_mutex = PTHREAD_MUTEX_INITIALIZER;
    int fd, screen;
    XCB_Connection *c;
    fd = XCB_Open(getenv("DISPLAY"), &screen);
    if(fd == -1)
    {
        perror("XCB_Open");
        abort();
    }

    pthread_mutex_lock(&nonce_mutex);
    c = XCB_Connect(fd, screen, nonce);
    nonce++;
    pthread_mutex_unlock(&nonce_mutex);
    if(!c)
    {
        perror("XCB_Connect");
        abort();
    }

    return c;
')
ENDXCBGEN
