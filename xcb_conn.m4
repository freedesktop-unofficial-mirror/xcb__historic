/* TODO:
 * Add better error handling, especially on pthreads calls
 */

XCBGEN(XCB_CONN)
_H
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
_C
_C`'#include "xcb_conn.h"

_H`'#define XCB_PAD(E) ((4-((E)%4))%4)
_H
STRUCT(XCB_Reply_Data, `
    FIELD(pthread_cond_t, `cond')
    FIELD(int, `pending')
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
    FIELD(int, `selecting')

    POINTERFIELD(XCB_Reply_Data, `reply_data_head')
    POINTERFIELD(XCB_Reply_Data, `reply_data_tail')
    FIELD(int, `recvd_seqnum')

    POINTERFIELD(XCB_Event_Data, `event_data_head')
    POINTERFIELD(XCB_Event_Data, `event_data_tail')
    FIELD(pthread_cond_t, `event_cond')
    FIELD(int, `event_pending')

    ARRAYFIELD(CARD8, `outqueue', 4096)
    FIELD(int, `n_outqueue')
    POINTERFIELD(struct iovec, `outvec')
    FIELD(int, `n_outvec')
    FIELD(pthread_cond_t, `flush_cond')
    FIELD(int, `flush_pending')

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
    ret = c->last_xid | c->setup.ridBase;
    c->last_xid += c->setup.ridMask & -(c->setup.ridMask);
    pthread_mutex_unlock(&c->locked);
    return ret;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`void XCB_Add_Reply_Data', `XCB_Connection *c, XCB_Reply_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->reply_data_tail)
        c->reply_data_tail->next = cur;
    else
        c->reply_data_head = cur;

    c->reply_data_tail = cur;
    return;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: *cur points at the desired data or is 0; if prev was not 0,
         (*prev)->next points at the desired data or *prev is 0 */
FUNCTION(`XCB_Reply_Data *XCB_Find_Reply_Data', `XCB_Connection *c, int seqnum', `
    XCB_Reply_Data *cur = c->reply_data_head;
    while(cur)
    {
        if(cur->seqnum == seqnum)
            return cur;
        cur = cur->next;
    }
    return 0;
')

/* PRE: c is locked */
/* POST: cur is no longer in the list (but the caller has to free it) */
FUNCTION(`int XCB_Remove_Reply_Data', `XCB_Connection *c, int seqnum', `
    XCB_Reply_Data *prev = 0, *cur = c->reply_data_head;

    while(cur)
    {
        if(cur->seqnum == seqnum)
            break;
        prev = cur;
        cur = cur->next;
    }

    if(!cur)
        return 0;

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
FUNCTION(`void XCB_Add_Event_Data', `XCB_Connection *c, XCB_Event_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->event_data_tail)
        c->event_data_tail->next = cur;
    else
        c->event_data_head = cur;

    c->event_data_tail = cur;
    return;
')
_C
_C`'#define XCB_SEQ_EARLIER(a, b) ((INT16) ((CARD16)a - (CARD16)b) < 0)
_C`'typedef enum { WAIT_SEQNUM, WAIT_EVENT, WAIT_FLUSH } wait_cmd_t;
_C
STATICFUNCTION(`void *XCB_Wait', `XCB_Connection *c, const wait_cmd_t cmd, const int prelocked, const int s, xError **e', `
    void *ret = 0;
    unsigned char *buf;
    XCB_Reply_Data *cur = 0, *tmp, *rep;
    fd_set rfds, wfds;
    int selret;

    if(e)
        *e = 0;

    if(!prelocked)
        pthread_mutex_lock(&c->locked);

    if(cmd == WAIT_SEQNUM)
    {
        cur = XCB_Find_Reply_Data(c, s);
        if(!cur) /* error: nothing found to hand back */
            goto done;

        if(cur->pending) /* error: someone else is already waiting */
            goto done;

        if(!XCB_SEQ_EARLIER(c->recvd_seqnum, s))
            goto extract_reply;

        assert(cur->data == 0);

        /* my reply not yet recvd */

        if(c->selecting)
        {
            cur->pending = 1;
            pthread_cond_wait(&cur->cond, &c->locked);
            cur->pending = 0;

            if(!XCB_SEQ_EARLIER(c->recvd_seqnum, s))
                goto extract_reply;
        }
    }
    else if(cmd == WAIT_EVENT)
    {
        if(c->event_data_head)
            goto extract_reply;

        /* my reply not yet recvd */

        if(c->selecting)
        {
            c->event_pending = 1;
            pthread_cond_wait(&c->event_cond, &c->locked);
            c->event_pending = 0;

            if(c->event_data_head)
                goto extract_reply;
        }
    }
    else if(cmd == WAIT_FLUSH)
    {
        if(!c->n_outqueue)
            goto done;

        /* my reply not yet recvd */

        if(c->selecting)
        {
            c->flush_pending = 1;
            pthread_cond_wait(&c->flush_cond, &c->locked);
            c->flush_pending = 0;

            if(!c->n_outqueue)
                goto done;
        }
    }

    /* i am in charge */

    c->selecting = 1;

    FD_ZERO(&rfds);
    FD_ZERO(&wfds);
ALLOC(unsigned char, buf, 32)

    while(1)
    {INDENT()
        FD_SET(c->fd, &rfds);
        // if(c->n_outqueue)
            FD_SET(c->fd, &wfds);

        pthread_mutex_unlock(&c->locked);
        selret = select(c->fd + 1, &rfds, &wfds, 0, 0);
        pthread_mutex_lock(&c->locked);

        /* if(selret <= 0) */ /* error: select failed */
        assert(selret > 0);

        if(FD_ISSET(c->fd, &rfds))
        {INDENT()
            if(read(c->fd, buf, 32) < 32)
                assert(0); /* FIXME: handle non-blocking I/O */

            if(!(buf[0] & ~1)) /* reply or error packet */
            {INDENT()
                c->recvd_seqnum = ((xGenericReply *) buf)->sequenceNumber;
                rep = XCB_Find_Reply_Data(c, c->recvd_seqnum);

                if(buf[0] == 1) /* get the payload for a reply packet */
                {INDENT()
                    CARD32 length = ((xGenericReply *) buf)->length;
                    if(length)
                    {INDENT()
REALLOC(unsigned char, buf, 32 + length * 4)

                        if(read(c->fd, buf + 32, length * 4) < length * 4)
                            assert(0); /* FIXME: handle non-blocking I/O */
                    }UNINDENT()
                }UNINDENT()
            }UNINDENT()
            else
                rep = 0;

            if(!rep)
            {INDENT()
                if(buf[0] != 1) /* event packet or unassociated error */
                {INDENT()
                    XCB_Event_Data *event;
ALLOC(XCB_Event_Data, event, 1)

                    event->event = (XCB_Event *) buf;
                    XCB_Add_Event_Data(c, event);
                    if(cmd == WAIT_EVENT)
                        break;
                    if(c->event_pending)
                        pthread_cond_signal(&c->event_cond);
                }UNINDENT()

                /* else error: no reply record for a reply. Ignore. */
            }UNINDENT()
            else
            {
                if(buf[0] == 0)
                    rep->error = 1;

                assert(rep->data == 0);
                rep->data = buf;
                if(cmd == WAIT_SEQNUM && !XCB_SEQ_EARLIER(c->recvd_seqnum, s))
                    break;
                if(rep->pending)
                    pthread_cond_signal(&rep->cond);
            }
        }UNINDENT()

        if(FD_ISSET(c->fd, &wfds))
        {INDENT()
            /* FIXME: non-blocking semantics */
            write(c->fd, c->outqueue, c->n_outqueue);
            c->n_outqueue = 0;
            if(c->n_outvec)
            {
                writev(c->fd, c->outvec, c->n_outvec);
                c->n_outvec = 0;
            }

            if(!c->n_outqueue)
            {
                if(cmd == WAIT_FLUSH)
                    break;
                if(c->flush_pending)
                    pthread_cond_signal(&c->flush_cond);
            }
        }UNINDENT()
    }UNINDENT()

    /* my reply is recvd */

    c->selecting = 0;

    /* note: if any threads are blocked after checking the selecting variable,
     * I must wake up *exactly* one of them, because whichever ones I wake
     * up will become selectors without checking whether that is OK. */

    if(c->event_pending)
        pthread_cond_signal(&c->event_cond);
    else if(c->flush_pending)
        pthread_cond_signal(&c->flush_cond);
    else
    {
        if(cmd == WAIT_SEQNUM)
            tmp = cur->next;
        else
            tmp = c->reply_data_head;

        while(tmp)
        {
            if(tmp->pending)
            {
                pthread_cond_signal(&tmp->cond);
                break;
            }
            tmp = tmp->next;
        }
    }

extract_reply:
    if(cmd == WAIT_SEQNUM)
    {
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

        XCB_Remove_Reply_Data(c, s);
        free(cur);
    }
    else if(cmd == WAIT_EVENT)
    {
        XCB_Event_Data *event = c->event_data_head;
        ret = event->event;
        c->event_data_head = event->next;
        if(!c->event_data_head)
            c->event_data_tail = 0;
        free(event);
    }

done:
    if(!prelocked)
        pthread_mutex_unlock(&c->locked);
    return ret;
')

FUNCTION(`void *XCB_Wait_Seqnum', `XCB_Connection *c, int seqnum, xError **e', `
    return XCB_Wait(c, WAIT_SEQNUM, 0, seqnum, e);
')
_C
FUNCTION(`XCB_Event *XCB_Wait_Event', `XCB_Connection *c', `
    return (XCB_Event *) XCB_Wait(c, WAIT_EVENT, 0, 0, 0);
')
_C
FUNCTION(`void XCB_Flush', `XCB_Connection *c', `
    XCB_Wait(c, WAIT_FLUSH, 0, 0, 0);
')
_C
FUNCTION(`void XCB_Flush_locked', `XCB_Connection *c', `
    XCB_Wait(c, WAIT_FLUSH, 1, 0, 0);
')

/* PRE: c is locked */
FUNCTION(`void XCB_Write', dnl
`XCB_Connection *c, struct iovec *vector, size_t count', `
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
        return;
    }

    c->outvec = vector;
    c->n_outvec = count;
    XCB_Flush_locked(c);
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

    if (fcntl(fd, F_SETFL, (long)O_NONBLOCK) == -1)
        return 0;
    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    c->selecting = 0;

    c->reply_data_head = 0;
    c->reply_data_tail = 0;
    c->recvd_seqnum = -1;

    c->event_data_head = 0;
    c->event_data_tail = 0;
    pthread_cond_init(&c->event_cond, 0);
    c->event_pending = 0;

    /* c->outqueue does not need initialization */
    c->n_outqueue = 0;
    /* c->outvec does not need initialization */
    c->n_outvec = 0;
    pthread_cond_init(&c->flush_cond, 0);
    c->flush_pending = 0;

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
    XCB_Flush(c);

    /* Read the server response */
    read(c->fd, &c->setup_prefix, SIZEOF(xConnSetupPrefix));

    clen += c->setup_prefix.length * 4 - SIZEOF(xConnSetup);
    c = (XCB_Connection *) realloc(c, clen);
    assert(c);
    read(c->fd, &c->setup, c->setup_prefix.length * 4);

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
