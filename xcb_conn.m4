XCBGEN(XCB_CONN)
_H
_H`'#include <pthread.h>
_H`'#include <sys/uio.h>
_C`'#include <assert.h>
_C`'#include <sys/types.h>
_C`'#include <sys/socket.h>
_C`'#include <sys/un.h>
_C`'#include <netinet/in.h>
_C`'#include <netdb.h>
_C`'#include <stdio.h>
_C`'#include <unistd.h>
_C`'#include <stdlib.h>
_C`'#include <errno.h>
#define NEED_EVENTS
#define NEED_REPLIES
#define ANSICPP
_H`'#include <X11/X.h>
_H`'#include <X11/Xproto.h>
_C
_C`'#include "xcb_conn.h"

_H`'#define XCB_PAD(E) ((4-((E)%4))%4)
_H
STRUCT(XCB_Reply_Data, `
    FIELD(int, `pending')
    FIELD(int, `received')
    FIELD(int, `error')
    FIELD(int, `seqnum')
    POINTERFIELD(void, `data')
    POINTERFIELD(struct XCB_Reply_Data, `next')
')
_H
UNION(XCB_Event, `
    FIELD(BYTE, `type')
    FIELD(xError, `error')
    FIELD(xEvent, `event')
    FIELD(xKeymapEvent, `keymapEvent')
')
_H
STRUCT(XCB_Event_Data, `
    POINTERFIELD(XCB_Event, `event')
    POINTERFIELD(struct XCB_Event_Data, `next')
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
    FIELD(pthread_mutex_t, `readlocked')
    FIELD(int, `seqnum')
    ARRAYFIELD(CARD8, `outqueue', 4096)
    FIELD(int, `n_outqueue')
    dnl FIELD(XCB_Atom_Dictionary, `atoms')
    FIELD(CARD32, `last_xid')

    POINTERFIELD(XCB_Reply_Data, `reply_data_head')
    POINTERFIELD(XCB_Reply_Data, `reply_data_tail')
    POINTERFIELD(XCB_Event_Data, `event_data_head')
    POINTERFIELD(XCB_Event_Data, `event_data_tail')

    POINTERFIELD(char, `vendor')
    POINTERFIELD(xPixmapFormat, `pixmapFormats')
    POINTERFIELD(XCB_WindowRoot, `roots')
    FIELD(xConnSetupPrefix, `setup_prefix')
    FIELD(xConnSetup, `setup')
')
_H
COOKIETYPE(`void')
_H
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
    ret = (c->last_xid += c->setup.ridMask & -(c->setup.ridMask)) | c->setup.ridBase;
    pthread_mutex_unlock(&c->locked);
    return ret;
')
_C
FUNCTION(`int XCB_Read', dnl
`XCB_Connection *c, unsigned char *buf, int len', `
    /* buffering here might be a win later */
    return read(c->fd, buf, len);
')

_C`'/* PRE: c is locked */
_C`'/* POST: c's queue has been flushed */
STATICFUNCTION(`int XCB_Flush_locked', `XCB_Connection *c', `
    int ret = 0;
    if(c->n_outqueue)
    {
        ret = write(c->fd, c->outqueue, c->n_outqueue);
        c->n_outqueue = 0;
    }
    return ret;
')
_C
FUNCTION(`int XCB_Flush', `XCB_Connection *c', `
    pthread_mutex_lock(&c->locked);
    XCB_Flush_locked(c);
    pthread_mutex_unlock(&c->locked);
    return 1;
')  

/* PRE: c is locked, vector points to valid memory, and count contains the
        number of entries in vector */
/* POST: if all of the data given would fit in the buffer, it has been copied
         there; otherwise, the contents of the buffer followed by the data
         have been written. */
FUNCTION(`int XCB_Write', dnl
`XCB_Connection *c, const struct iovec *vector, const size_t count', `
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
        return len;
    }

    /* If there was something in the queue already, make sure to send it
     * before the new data. */
    if(c->n_outqueue)
    {INDENT()
        struct iovec *v;
        int ret;

ALLOC(struct iovec, v, count + 1)
        v[0].iov_base = c->outqueue;
        v[0].iov_len = c->n_outqueue;
        memcpy(v + 1, vector, sizeof(struct iovec) * (count + 1));
        ret = writev(c->fd, v, count + 1);
        free(v);

        return ret;
    }UNINDENT()

    /* Nothing was in the queue, but this is a really big request. */
    return writev(c->fd, vector, count);
')

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`int XCB_Add_Reply_Data', dnl
`XCB_Connection *c, XCB_Reply_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->reply_data_tail)
        c->reply_data_tail->next = cur;
    else
        c->reply_data_head = cur;

    c->reply_data_tail = cur;
    return 1;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: *cur points at the desired data or is 0; if prev was not 0,
         (*prev)->next points at the desired data or *prev is 0 */
FUNCTION(`int XCB_Find_Reply_Data', dnl
`XCB_Connection *c, int seqnum, XCB_Reply_Data **cur, XCB_Reply_Data **prev', `
    assert(cur);
    if(prev)
        *prev = 0;
    *cur = c->reply_data_head;
    while(*cur)
    {
        if((*cur)->seqnum == seqnum)
            break;
        if(prev)
            *prev = *cur;
        *cur = (*cur)->next;
    }
    return 1;
')

/* PRE: c is locked, cur points to valid memory, and prev points to the
        immediate predecessor to cur or is 0 if cur is the first item in
        the list */
/* POST: cur is no longer in the list (but the caller has to free it) */
FUNCTION(`int XCB_Remove_Reply_Data', dnl
`XCB_Connection *c, XCB_Reply_Data *cur, XCB_Reply_Data *prev', `
    assert(cur);
    assert(prev ? prev->next == cur : c->reply_data_head == cur);

    if(prev)
        prev->next = cur->next;
    else
        c->reply_data_head = cur->next;

    if(!cur->next)
        c->reply_data_tail = prev;

    return 1;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`int XCB_Add_Event_Data', dnl
`XCB_Connection *c, XCB_Event_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->event_data_tail)
        c->event_data_tail->next = cur;
    else
        c->event_data_head = cur;

    c->event_data_tail = cur;
    return 1;
')
_C
_C`/* Note that we assume that XCB_Wait_Once and XCB_Wait_Seqnum are the'
_C` * _only_ functions which touch the reply_data list. These two can be'
_C` * checked for thread-safety while making optimizing assumptions. */'
_C
_C`'/* PRE: c is locked */
STATICFUNCTION(`int XCB_Wait_Once', `XCB_Connection *c', `
    unsigned char *buf;
ALLOC(unsigned char, buf, 32)

    if(XCB_Read(c, buf, 32) < 32)
        return 0;

    switch(buf[0])
    {INDENT()
        XCB_Reply_Data *rep;
        int seqnum;
        CARD32 length;

    case 1: /* reply */
        seqnum = ((xGenericReply *) buf)->sequenceNumber;
        XCB_Find_Reply_Data(c, seqnum, &rep, 0);
        if(!rep)
        {
            printf("Got reply for seqnum %d but no data found!\n", seqnum);
            return 0;
        }

        length = ((xGenericReply *) buf)->length;
        if(length)
        {INDENT()
REALLOC(unsigned char, buf, 32 + length * 4)
            XCB_Read(c, buf + 32, length * 4);
        }UNINDENT()

        rep->data = buf;
        rep->received = 1;
        break;

    case 0: /* error */
        XCB_Find_Reply_Data(c, ((xError *) buf)->sequenceNumber, &rep, 0);
        if(rep) /* add this error to the reply data */
        {
            free(rep->data); /* I hope this is always a no-op */
            rep->data = buf;
            rep->error = rep->received = 1;
            break; /* do not add to the event queue */
        }

        /* FALLTHROUGH */ /* add this error to the event queue */
    default: /* event */
        {INDENT()
            XCB_Event_Data *cur;
ALLOC(XCB_Event_Data, cur, 1)

            cur->event = (XCB_Event *) buf;
            XCB_Add_Event_Data(c, cur);
        }UNINDENT()
    }UNINDENT()

    return 1;
')

/* PRE: c is unlocked */
FUNCTION(`void *XCB_Wait_Seqnum', dnl
`XCB_Connection *c, int seqnum, xError **e', `
    void *ret = 0;
    XCB_Reply_Data *cur, *prev;

    if(e)
        *e = 0;

    pthread_mutex_lock(&c->locked);
    XCB_Flush_locked(c);
    pthread_mutex_unlock(&c->locked);

    pthread_mutex_lock(&c->readlocked);
    XCB_Find_Reply_Data(c, seqnum, &cur, &prev);
    if(!cur) /* nothing found to hand back */
        goto done;

    if(cur->pending) /* someone else is already waiting */
        goto done;
    ++cur->pending;

    while(1) /* wait for the reply to arrive */
    {
        if(cur->received) break;
        if(!XCB_Wait_Once(c)) goto done;
        if(cur->received) break;

        /* CHECKME: Want to let other threads run here. Is this OK? */
        /* No. It is not. */
        pthread_mutex_unlock(&c->readlocked);
        pthread_mutex_lock(&c->readlocked);
    }

    if(cur->error)
    {INDENT()
        if(!e)
        {INDENT()
            XCB_Event_Data *event;
ALLOC(XCB_Event_Data, event, 1)

            event->event = (XCB_Event *) cur->data;
            XCB_Add_Event_Data(c, event);
        }UNINDENT()
        else
            *e = (xError *) cur->data;
    }UNINDENT()
    else
        ret = cur->data;

    XCB_Remove_Reply_Data(c, cur, prev);
    free(cur);

done:
    pthread_mutex_unlock(&c->readlocked);
    return ret;
')

/* It is the caller's responsibility to free the returned XCB_Event object. */
FUNCTION(`XCB_Event *XCB_Wait_Event', `XCB_Connection *c', `
    XCB_Event *ret = 0;
    XCB_Event_Data *cur;

    pthread_mutex_lock(&c->readlocked);
    while(1) /* wait for an event to arrive */
    {
        if(c->event_data_head) break;
        if(!XCB_Wait_Once(c)) goto done;
        if(c->event_data_head) break;

        /* CHECKME: Want to let other threads run here. Is this OK? */
        /* No. It is not. */
        pthread_mutex_unlock(&c->readlocked);
        pthread_mutex_lock(&c->readlocked);
    }

    cur = c->event_data_head;
    ret = cur->event;
    c->event_data_head = cur->next;
    if(!c->event_data_head)
        c->event_data_tail = 0;
    free(cur);

done:
    pthread_mutex_unlock(&c->readlocked);
    return ret;
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

    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    pthread_mutex_init(&c->readlocked, 0);
    c->n_outqueue = 0;
    c->seqnum = 0;
    c->last_xid = 0;
    c->reply_data_head = 0;
    c->reply_data_tail = 0;
    c->event_data_head = 0;
    c->event_data_tail = 0;

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
    XCB_Flush_locked(c);

    /* Read the server response */
    read(c->fd, &c->setup_prefix, SIZEOF(xConnSetupPrefix));
    /* 0 = failed, 2 = authenticate, 1 = success */
    switch(c->setup_prefix.success)
    {
    case 0: /* failed */
    case 2: /* authenticate */
        free(c);
        return 0; /* aw, screw you. */
    }

    clen += c->setup_prefix.length * 4 - SIZEOF(xConnSetup);
    c = (XCB_Connection *) realloc(c, clen);
    assert(c);
    read(c->fd, &c->setup, c->setup_prefix.length * 4);

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
