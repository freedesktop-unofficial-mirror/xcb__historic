#include <assert.h>
#include <X11/Xauth.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/param.h>
#include <unistd.h>

#include "xcb.h"
#include "xcbint.h"

#define XA1 "XDM-AUTHORIZATION-1"
#define MC1 "MIT-MAGIC-COOKIE-1"
static char *authtypes[] = { /* XA1, */ MC1 };
static int authtypelens[] = { /* sizeof(XA1)-1, */ sizeof(MC1)-1 };

int XCBNextNonce()
{
    static int nonce = 0;
    static pthread_mutex_t nonce_mutex = PTHREAD_MUTEX_INITIALIZER;
    int ret;
    pthread_mutex_lock(&nonce_mutex);
    ret = nonce++;
    pthread_mutex_unlock(&nonce_mutex);
    return ret;
}

XCBAuthInfo *XCBGetAuthInfo(int fd, int nonce, XCBAuthInfo *info)
{
    /* code adapted from Xlib/ConnDis.c, xtrans/Xtranssocket.c,
       xtrans/Xtransutils.c */
    char sockbuf[sizeof(struct sockaddr) + MAXPATHLEN];
    unsigned int socknamelen = sizeof(sockbuf);   /* need extra space */
    struct sockaddr *sockname = (struct sockaddr *) &sockbuf;
    char *addr = 0;
    int addrlen = 0;
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
