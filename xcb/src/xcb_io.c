/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#define _GNU_SOURCE /* for asprintf */

#include <assert.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include "xcb.h"
#include "xcbint.h"

#define USENONBLOCKING

struct XCBIOHandle {
    int fd;
    pthread_mutex_t *locked;
    pthread_cond_t waiting_threads;
    int reading;
    int writing;
    char inqueue[1 << 18];
    int n_inqueue;
    char outqueue[1 << 18];
    int n_outqueue;
    struct iovec *outvec;
    int n_outvec;

    XCBIOCallback reader;
    void *readerdata;
};

XCBIOHandle *XCBIOFdOpen(int fd, pthread_mutex_t *locked)
{
    XCBIOHandle *h;
    long flags;

    h = (XCBIOHandle *) malloc((1) * sizeof(XCBIOHandle));
    if(!h)
        return 0;

    flags = fcntl(fd, F_GETFL, 0);
    if (flags == -1)
	return 0;
    flags |= O_NONBLOCK;
    if (fcntl(fd, F_SETFL, flags) == -1)
	return 0;

    h->fd = fd;
    h->locked = locked;
    pthread_cond_init(&h->waiting_threads, 0);
    h->reading = 0;
    h->writing = 0;
    /* h->inqueue does not need initialization */
    h->n_inqueue = 0;
    /* h->outqueue does not need initialization */
    h->n_outqueue = 0;
    h->outvec = 0;
    h->n_outvec = 0;
    h->reader = 0;
    h->readerdata = 0;

    return h;
}

void XCBIOSetReader(XCBIOHandle *h, XCBIOCallback reader, void *readerdata)
{
    h->reader = reader;
    h->readerdata = readerdata;
}

void *XCBAllocOut(XCBIOHandle *c, int size)
{
    void *out;
    if(c->n_outvec || c->n_outqueue + size > sizeof(c->outqueue))
    {
        int ret = XCBFlushLocked(c);
        if(ret <= 0)
        {
            fputs("XCB error: flush failed in XCBAllocOut\n", stderr);
            abort();
        }
    }

    out = c->outqueue + c->n_outqueue;
    c->n_outqueue += size;
    assert(c->n_outqueue <= sizeof(c->outqueue));
    return out;
}

static int XCBWriteBuffer(XCBIOHandle *c)
{
    int i, n;
    if(!c->n_outvec)
    {
        n = write(c->fd, c->outqueue, c->n_outqueue);
        if(n < 0)
            return errno == EAGAIN ? 1 : -1;
        c->n_outqueue -= n;
        if(c->n_outqueue)
            memmove(c->outqueue, c->outqueue + n, c->n_outqueue);
        return 1;
    }

    n = writev(c->fd, c->outvec, c->n_outvec);
    if(n < 0)
        return errno == EAGAIN ? 1 : -1;
    for(i = 0; i < c->n_outvec; ++i)
    {
        int cur = c->outvec[i].iov_len;
        if(cur > n)
            cur = n;
        c->outvec[i].iov_len -= cur;
        c->outvec[i].iov_base = (char *) c->outvec[i].iov_base + cur;
        n -= cur;
        if(c->outvec[i].iov_len)
            break;
    }
    assert(n == 0);
    assert(i == c->n_outvec || (i < c->n_outvec && c->outvec[i].iov_len > 0));
    c->n_outvec -= i;
    if(c->n_outvec)
        memmove(c->outvec, c->outvec + i, c->n_outvec * sizeof(struct iovec));
    return 1;
}

int XCBFillBuffer(XCBIOHandle *h)
{
    int ret;
    ret = read(h->fd, h->inqueue + h->n_inqueue, sizeof(h->inqueue) - h->n_inqueue);
    if(ret < 0)
        return errno == EAGAIN ? 1 : -1;
    h->n_inqueue += ret;
    if(h->reader)
        while(ret > 0)
            ret = h->reader(h->readerdata, h);
    return 1;
}

int XCBWait(XCBIOHandle *c, const int should_write)
{
    int ret = 1;
    fd_set rfds, wfds;

    /* If the thing I should be doing is already being done, wait for it. */
    if(should_write ? c->writing : c->reading)
    {
        pthread_cond_wait(&c->waiting_threads, c->locked);
        return 1;
    }

    FD_ZERO(&rfds);
    FD_SET(c->fd, &rfds);
    ++c->reading;

    FD_ZERO(&wfds);
    if(should_write)
    {
        FD_SET(c->fd, &wfds);
        ++c->writing;
    }

    pthread_mutex_unlock(c->locked);
    ret = select(c->fd + 1, &rfds, &wfds, 0, 0);
    pthread_mutex_lock(c->locked);

    if(ret <= 0) /* error: select failed */
        goto done;

    if(FD_ISSET(c->fd, &rfds))
        if((ret = XCBFillBuffer(c)) <= 0)
            goto done;

    if(FD_ISSET(c->fd, &wfds))
        if((ret = XCBWriteBuffer(c)) <= 0)
            goto done;

done:
    /* Wake up anyone affected by whatever I just did. */
    pthread_cond_broadcast(&c->waiting_threads);

    if(should_write)
        --c->writing;
    --c->reading;

    return ret;
}

int XCBFlushLocked(XCBIOHandle *c)
{
    int ret = 1;
    while(ret >= 0 && (c->n_outqueue || c->n_outvec))
        ret = XCBWait(c, /*should_write*/ 1);
    return ret;
}

int XCBWrite(XCBIOHandle *c, struct iovec *vector, size_t count)
{
    static const char pad[3];
    int i, len;

    for(i = 0, len = 0; i < count; ++i)
        len += XCB_CEIL(vector[i].iov_len);

    /* Is the queue about to overflow? */
    if(c->n_outqueue + len < sizeof(c->outqueue))
    {
        /* No, this will fit. */
        for(i = 0; i < count; ++i)
        {
            memcpy(c->outqueue + c->n_outqueue, vector[i].iov_base, vector[i].iov_len);
            if(vector[i].iov_len & 3)
                memset(c->outqueue + c->n_outqueue + vector[i].iov_len, 0, XCB_PAD(vector[i].iov_len));
            c->n_outqueue += XCB_CEIL(vector[i].iov_len);
        }
        return len;
    }

    assert(!c->n_outvec);
    c->outvec = malloc(sizeof(struct iovec) * (1 + count * 2));
    if(!c->outvec)
        return -1;
    if(c->n_outqueue)
    {
        c->outvec[c->n_outvec].iov_base = c->outqueue;
        c->outvec[c->n_outvec++].iov_len = c->n_outqueue;
        c->n_outqueue = 0;
    }
    for(i = 0; i < count; ++i)
    {
        if(!vector[i].iov_len)
            continue;
        c->outvec[c->n_outvec].iov_base = vector[i].iov_base;
        c->outvec[c->n_outvec++].iov_len = vector[i].iov_len;
        if(!XCB_PAD(vector[i].iov_len))
            continue;
        c->outvec[c->n_outvec].iov_base = (caddr_t) pad;
        c->outvec[c->n_outvec++].iov_len = XCB_PAD(vector[i].iov_len);
    }
    if(XCBFlushLocked(c) < 0)
        return -1;
    free(c->outvec);
    c->outvec = 0;

    return len;
}

int XCBRead(XCBIOHandle *h, void *target, int len)
{
    int nread = 0, saved_reading;
    XCBIOCallback saved_reader;
    unsigned char *buf = target;
    if(!len)
        return nread;

    /* save everything that's read into the buffer for me! */
    saved_reader = h->reader;
    h->reader = 0;
    saved_reading = h->reading;
    h->reading = 0;

    do
    {
        int cur;
        /* cur = min(len, h->n_inqueue) */
        if(len < h->n_inqueue)
            cur = len;
        else
            cur = h->n_inqueue;
        /* get cur bytes from inqueue */
        memcpy(buf, h->inqueue, cur);
        h->n_inqueue -= cur;
        if(h->n_inqueue)
            memmove(h->inqueue, h->inqueue + cur, h->n_inqueue);
        nread += cur;
        buf += cur;
        len -= cur;
    }
    while(len && XCBWait(h, /* should_write */ 0) > 0);

    h->reader = saved_reader;
    h->reading = saved_reading;

    return nread;
}

int XCBIOPeek(XCBIOHandle *h, void *buf, int nread)
{
    assert(nread <= sizeof(h->inqueue));
    if(nread > h->n_inqueue)
        nread = h->n_inqueue;
    if(!nread)
        return 0;
    memcpy(buf, h->inqueue, nread);
    return nread;
}

int XCBIOReadable(XCBIOHandle *h)
{
    return h->n_inqueue;
}

int XCBOpen(const char *host, int display)
{
    int fd;

    if(*host)
    {
        /* display specifies TCP */
        unsigned short port = X_TCP_PORT + display;
        fd = XCBOpenTCP(host, port);
    }
    else
    {
        /* display specifies Unix socket */
        char *file;
        asprintf(&file, "/tmp/.X11-unix/X%d", display);
        fd = XCBOpenUnix(file);
        free(file);
    }

    return fd;
}

int XCBOpenTCP(const char *host, unsigned short port)
{
    int fd;
    struct sockaddr_in addr;
    struct hostent *hostaddr = gethostbyname(host);
    if(!hostaddr)
        return -1;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    memcpy(&addr.sin_addr, hostaddr->h_addr_list[0], sizeof(addr.sin_addr));

    fd = socket(PF_INET, SOCK_STREAM, 0);
    if(fd == -1)
        return -1;
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
}

int XCBOpenUnix(const char *file)
{
    int fd;
    struct sockaddr_un addr = { AF_UNIX };
    strcpy(addr.sun_path, file);

    fd = socket(PF_UNIX, SOCK_STREAM, 0);
    if(fd == -1)
        return -1;
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
}
