/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

/* Utility functions implementable using only public APIs. */

#include <assert.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "xcb.h"

int XCBOnes(unsigned long mask)
{
    unsigned long y;
    y = (mask >> 1) & 033333333333;
    y = mask - y - ((y >> 1) & 033333333333);
    return ((y + (y >> 3)) & 030707070707) % 077;
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

int XCBOpen(const char *host, const int display)
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
        static const char base[] = "/tmp/.X11-unix/X";
        char file[sizeof(base) + 20];
        snprintf(file, sizeof(file), "%s%d", base, display);
        fd = XCBOpenUnix(file);
    }

    return fd;
}

int XCBOpenTCP(const char *host, const unsigned short port)
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

XCBConnection *XCBConnectBasic()
{
    int fd, display = 0, screen = 0;
    char *host;
    XCBConnection *c;
    XCBAuthInfo auth;

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

    XCBGetAuthInfo(fd, XCBNextNonce(), &auth);
    c = XCBConnect(fd, &auth);
    if(!c)
    {
        perror("XCBConnect");
        abort();
    }

    free(auth.name);
    free(auth.data);
    return c;
}

int XCBSync(XCBConnection *c, XCBGenericError **e)
{
    XCBGetInputFocusRep *reply = XCBGetInputFocusReply(c, XCBGetInputFocus(c), e);
    free(reply);
    return reply != 0;
}

/* The functions beyond this point still use only public interfaces,
 * but are not themselves part of the public interface. So their
 * prototypes are in xcbint.h. */

#include "xcbint.h"

int _xcb_set_fd_flags(const int fd)
{
    long flags = fcntl(fd, F_GETFL, 0);
    if(flags == -1)
        return 0;
    flags |= O_NONBLOCK;
    if(fcntl(fd, F_SETFL, flags) == -1)
        return 0;
    if(fcntl(fd, F_SETFD, FD_CLOEXEC) == -1)
        return 0;
    return 1;
}

int _xcb_readn(const int fd, void *buf, const int buflen, int *count)
{
    int n = read(fd, ((char *) buf) + *count, buflen - *count);
    if(n > 0)
        *count += n;
    return n;
}

int _xcb_read_block(const int fd, void *buf, const size_t len)
{
    int done = 0;
    while(done < len)
    {
        int ret = _xcb_readn(fd, buf, len, &done);
        if(ret < 0 && errno == EAGAIN)
        {
            fd_set fds;
            FD_ZERO(&fds);
            FD_SET(fd, &fds);
            ret = select(fd + 1, &fds, 0, 0, 0);
        }
        if(ret <= 0)
            return ret;
    }
    return len;
}

int _xcb_write(const int fd, char (*buf)[], int *count)
{
    int n = write(fd, *buf, *count);
    if(n > 0)
    {
        *count -= n;
        if(*count)
            memmove(*buf, *buf + n, *count);
    }
    return n;
}

int _xcb_writev(const int fd, struct iovec *vec, int count)
{
    int n = writev(fd, vec, count);
    if(n > 0)
    {
        int rem = n;
        for(; count; --count, ++vec)
        {
            int cur = vec->iov_len;
            if(cur > rem)
                cur = rem;
            vec->iov_len -= cur;
            vec->iov_base = (char *) vec->iov_base + cur;
            rem -= cur;
            if(vec->iov_len)
                break;
        }
        assert(rem == 0);
    }
    return n;
}
