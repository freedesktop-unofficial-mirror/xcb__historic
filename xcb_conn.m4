/* TODO:
 * Add better error handling, especially on pthreads calls
 */

XCBGEN(XCB_CONN)
_H`'#include <sys/uio.h>
_C`'#include <sys/types.h>
_C`'#include <sys/socket.h>
_C`'#include <sys/fcntl.h>
_C`'#include <sys/un.h>
_C`'#include <netinet/in.h>
_C`'#include <netdb.h>
_C`'#include <assert.h>
_C`'#include <stdio.h>
_C`'#include <unistd.h>
_C`'#include <stdlib.h>
_C`'#include <errno.h>
_H`'#include <pthread.h>
_H
_H`'#define NEED_EVENTS
_H`'#define NEED_REPLIES
_H`'#define ANSICPP
_H`'#include <X11/X.h>
_H`'#include <X11/Xproto.h>

_C`'#undef USENONBLOCKING
_H`'#define XCB_PAD(E) ((4-((E)%4))%4)
_H`'#define X_TCP_PORT 6000	/* add display number */

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
_H
UNION(XCB_Event, `
    FIELD(BYTE, `type')
    FIELD(xError, `error')
    FIELD(xEvent, `event')
    FIELD(xKeymapEvent, `keymapEvent')
')
_H
STRUCT(XCB_Depth, `
    POINTERFIELD(xDepth, `data')
    POINTERFIELD(xVisualType, `visuals')
')
_H
STRUCT(XCB_WindowRoot, `
    POINTERFIELD(xWindowRoot, `data')
    POINTERFIELD(XCB_Depth, `depths')
')
_H
STRUCT(XCB_Connection, `
    FIELD(int, `fd')
    FIELD(pthread_mutex_t, `locked')
    FIELD(pthread_cond_t, `waiting_threads')
    FIELD(int, `reading')
    FIELD(int, `writing')

    FIELD(XCB_List, `reply_data')
    FIELD(XCB_List, `event_data')

    ARRAYFIELD(CARD8, `outqueue', 4096)
    FIELD(int, `n_outqueue')
    POINTERFIELD(struct iovec, `outvec')
    FIELD(int, `n_outvec')

    FIELD(int, `seqnum')
    FIELD(CARD32, `last_xid')

    dnl FIELD(XCB_Atom_Dictionary, `atoms')

    POINTERFIELD(char, `vendor')
    POINTERFIELD(xPixmapFormat, `pixmapFormats')
    POINTERFIELD(XCB_WindowRoot, `roots')
    FIELD(xConnSetupPrefix, `setup_prefix')
    FIELD(xConnSetup, `setup')
')
_H
COOKIETYPE(`void')

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
    ret = c->last_xid | c->setup.ridBase;
    c->last_xid += c->setup.ridMask & -(c->setup.ridMask);
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`void *XCB_Alloc_Out', `XCB_Connection *c, int size', `
    void *out;
    if(c->n_outvec || c->n_outqueue + size > sizeof(c->outqueue))
        assert(XCB_Flush_locked(c) > 0);

    out = c->outqueue + c->n_outqueue;
    c->n_outqueue += size;
    assert(c->n_outqueue <= sizeof(c->outqueue));
    return out;
')

/* Linked list functions */

STATICFUNCTION(`void list_init', `XCB_List *list', `
    list->head = list->tail = 0;
')

STATICFUNCTION(`void list_insert', `XCB_List *list, void *data', `
    XCB_ListNode *node;
ALLOC(XCB_ListNode, `node', 1)
    node->data = data;

    node->next = list->head;
    list->head = node;
    if(!list->tail)
        list->tail = node;
')

STATICFUNCTION(`void list_append', `XCB_List *list, void *data', `
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

STATICFUNCTION(`void *list_remove_head', `XCB_List *list', `
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

STATICFUNCTION(`void *list_remove', `XCB_List *list, int (*cmp)(void *, void *), void *data', `
    XCB_ListNode *prev = 0, *cur = list->head;

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

    data = cur->data;
    free(cur);
    return data;
')

STATICFUNCTION(`void *list_find', `XCB_List *list, int (*cmp)(void *, void *), void *data', `
    XCB_ListNode *cur = list->head;
    while(cur)
    {
        if(cmp(data, cur->data))
            return cur->data;
        cur = cur->next;
    }
    return 0;
')

STATICFUNCTION(`int list_is_empty', `XCB_List *list', `
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

    list_append(&c->reply_data, data);
')

STATICFUNCTION(`int match_reply_seqnum', `void *seqnum, void *data', `
    return (((XCB_Reply_Data *) data)->seqnum == *(int *) seqnum);
')

/* PRE: c is locked and cur points to valid memory */
/* POST: *cur points at the desired data or is 0; if prev was not 0,
         (*prev)->next points at the desired data or *prev is 0 */
STATICFUNCTION(`XCB_Reply_Data *XCB_Find_Reply_Data', `XCB_Connection *c, int seqnum', `
    return (XCB_Reply_Data *) list_find(&c->reply_data, match_reply_seqnum, &seqnum);
')

FUNCTION(`int XCB_EventQueueIsEmpty', `XCB_Connection *c', `
    return list_is_empty(&c->event_data);
')

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
_C
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
_C
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
        CARD32 length = ((xGenericReply *) buf)->length;
        if(length)
        {INDENT()
REALLOC(unsigned char, buf, 32 + length * 4)

            ret = XCB_read_internal(c, buf + 32, length * 4);
            if(ret != length * 4)
                return (ret <= 0) ? ret : -1;
        }UNINDENT()
    }UNINDENT()

    if(!(buf[0] & ~1)) /* reply or error packet */
        rep = XCB_Find_Reply_Data(c, ((xGenericReply *) buf)->sequenceNumber);

    if(buf[0] == 1 && !rep) /* I see no reply record here, but I need one. */
    {
        fprintf(stderr, "No reply record found for reply %d.\n", ((xGenericReply *) buf)->sequenceNumber);
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
        list_append(&c->event_data, (XCB_Event *) buf);

    return 1; /* I have something for you... */
')
_C
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
_C
STATICFUNCTION(`int XCB_Wait', `XCB_Connection *c, const int should_write', `
    int ret = 1, should_read;
    fd_set rfds, wfds;

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

FUNCTION(`void *XCB_Wait_Seqnum', `XCB_Connection *c, int seqnum, xError **e', `
    void *ret = 0;
    XCB_Reply_Data *cur;
    if(e)
        *e = 0;

    pthread_mutex_lock(&c->locked);
    cur = XCB_Find_Reply_Data(c, seqnum);

    if(!cur || cur->pending) /* error */
        goto done;

    ++cur->pending;

    assert(XCB_Flush_locked(c) > 0);
    while(!cur->data)
    {
        if(c->reading)
            pthread_cond_wait(&c->waiting_threads, &c->locked);
        else
            if(XCB_Wait(c, /*should_write*/ 0) <= 0)
                break;
    }

    --cur->pending;

    if(cur->error)
    {
        if(!e)
            list_append(&c->event_data, (XCB_Event *) cur->data);
        else
            *e = (xError *) cur->data;
    }
    else
        ret = cur->data;

    if(ret)
    {
        list_remove(&c->reply_data, match_reply_seqnum, &seqnum);
        free(cur);
    }

done:
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`XCB_Event *XCB_Wait_Event', `XCB_Connection *c', `
    void *ret;

    pthread_mutex_lock(&c->locked);
    while(list_is_empty(&c->event_data))
    {
        if(c->reading)
            pthread_cond_wait(&c->waiting_threads, &c->locked);
        else
            if(XCB_Wait(c, /*should_write*/ 0) <= 0)
                break;
    }
    ret = list_remove_head(&c->event_data);

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
    {
        if(c->writing)
            pthread_cond_wait(&c->waiting_threads, &c->locked);
        else
            ret = XCB_Wait(c, /*should_write*/ 1);
    }
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
        assert(XCB_Flush_locked(c) > 0);
        return;
    }

    assert(0);  /* FIXME: turning off outvec support */
    c->outvec = vector;
    c->n_outvec = count;
    assert(XCB_Flush_locked(c) > 0);
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

    colon = strchr(buf, '':'`);
    if(!colon)
    {
        printf("Error: invalid display: \"%s\"\n", buf);
        return -1;
    }
    *colon = ''\0'`;
    ++colon;

    dot = strchr(colon, ''.'`);
    if(dot)
    {
        *dot = ''\0'`;
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
FUNCTION(`XCB_Connection *XCB_Connect', `int fd', `
    XCB_Connection* c;
    size_t clen = sizeof(XCB_Connection);

ALLOC(XCB_Connection, c, 1)

#ifdef USENONBLOCKING
    if (fcntl(fd, F_SETFL, (long)O_NONBLOCK) == -1)
        return 0;
#endif
    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    c->reading = 0;
    c->writing = 0;

    list_init(&c->reply_data);
    list_init(&c->event_data);

    /* c->outqueue does not need initialization */
    c->n_outqueue = 0;
    /* c->outvec does not need initialization */
    c->n_outvec = 0;

    c->seqnum = 0;
    c->last_xid = 0;

    /* Write the connection setup request. */
    {
        xConnClientPrefix *out = (xConnClientPrefix *) c->outqueue;
        c->n_outqueue = SIZEOF(xConnClientPrefix);

        /* B = 0x42 = MSB first, l = 0x6c = LSB first */
        out->byteOrder = 0x6c;
        out->majorVersion = X_PROTOCOL;
        out->minorVersion = X_PROTOCOL_REVISION;
        /* Auth protocol name and data are both zero-length for now */
        out->nbytesAuthProto = 0;
        out->nbytesAuthString = 0;
    }
    assert(XCB_Flush(c) > 0);

    /* Read the server response */
    assert(XCB_read_internal(c, &c->setup_prefix, SIZEOF(xConnSetupPrefix))
      == SIZEOF(xConnSetupPrefix));

    clen += c->setup_prefix.length * 4 - SIZEOF(xConnSetup);
    c = (XCB_Connection *) realloc(c, clen);
    assert(c);
    assert(XCB_read_internal(c, &c->setup, c->setup_prefix.length * 4)
      == c->setup_prefix.length * 4);

    /* 0 = failed, 2 = authenticate, 1 = success */
    switch(c->setup_prefix.success)
    {
    case 0: /* failed */
        fflush(stderr);
        write(STDERR_FILENO, &c->setup, c->setup_prefix.lengthReason);
        write(STDERR_FILENO, "\n", sizeof("\n"));
        /*FALLTHROUGH*/
    case 2: /* authenticate */
        free(c);
        return 0;
    }

    /* Set up a collection of convenience pointers. */
    /* Initialize these since they are used before the next realloc. */
    c->vendor = (char *) (c + 1);
    c->pixmapFormats = (xPixmapFormat *) (c->vendor + c->setup.nbytesVendor + XCB_PAD(c->setup.nbytesVendor));

    /* So, just how obscure *can* a person make memory management? */
    {
        xWindowRoot *root;
        xDepth *depth;
        XCB_Depth *xpdepth;
        xVisualType *visual;
        int i, j, oldclen = clen;

        clen += sizeof(XCB_WindowRoot) * c->setup.numRoots;

        root = (xWindowRoot *) (c->pixmapFormats + c->setup.numFormats);
        for(i = 0; i < c->setup.numRoots; ++i)
        {
            clen += sizeof(XCB_Depth) * root->nDepths;

            depth = (xDepth *) (root + 1);
            for(j = 0; j < root->nDepths; ++j)
            {
                visual = (xVisualType *) (depth + 1);
                depth = (xDepth *) (visual + depth->nVisuals);
            }
            root = (xWindowRoot *) depth;
        }

        c = (XCB_Connection *) realloc(c, clen);
        assert(c);

        /* Re-initialize these since realloc probably moved them. */
        c->vendor = (char *) (c + 1);
        c->pixmapFormats = (xPixmapFormat *) (c->vendor + c->setup.nbytesVendor + XCB_PAD(c->setup.nbytesVendor));

        c->roots = (XCB_WindowRoot *) (((char *) c) + oldclen);
        xpdepth = (XCB_Depth *) (c->roots + c->setup.numRoots);

        root = (xWindowRoot *) (c->pixmapFormats + c->setup.numFormats);
        for(i = 0; i < c->setup.numRoots; ++i)
        {
            c->roots[i].data = root;
            c->roots[i].depths = xpdepth;

            depth = (xDepth *) (root + 1);
            xpdepth += root->nDepths;
            for(j = 0; j < root->nDepths; ++j)
            {
                c->roots[i].depths[j].data = depth;
                visual = (xVisualType *) (depth + 1);
                c->roots[i].depths[j].visuals = visual;
                depth = (xDepth *) (visual + depth->nVisuals);
            }
            root = (xWindowRoot *) depth;
        }
    }

    return c;
')
_C
FUNCTION(`XCB_Connection *XCB_Connect_Basic', `', `
    int fd, screen;
    XCB_Connection *c;
    fd = XCB_Open(getenv("DISPLAY"), &screen);
    if(fd == -1)
    {
        perror("XCB_Open");
        abort();
    }

    c = XCB_Connect(fd);
    if(!c)
    {
        perror("XCB_Connect");
        abort();
    }

    return c;
')
_H
ENDXCBGEN
