#include <assert.h>
#include <X11/Xauth.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/un.h>
#include <sys/param.h>
#include <unistd.h>

#include "xcb.h"
#include "xcbint.h"
#include "xcb_des.h"

enum auth_protos {
#ifdef HAS_AUTH_XA1
    AUTH_XA1,
#endif
    AUTH_MC1,
    N_AUTH_PROTOS
};

static char *authnames[N_AUTH_PROTOS] = {
#ifdef HAS_AUTH_XA1
    "XDM-AUTHORIZATION-1",
#endif
    "MIT-MAGIC-COOKIE-1",
};

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

#ifdef HAS_AUTH_XA1

/*
 * This code and the code it calls is taken from libXdmcp,
 * specifically from Wrap.c, Wrap.h, and Wraphelp.c.  The US
 * has changed, thank goodness, and it should be OK to bury
 * DES code in an open source product without a maze of
 * twisty wrapper functions stored offshore.  Or maybe
 * not. --Bart Massey 2003/11/5
 */

static void
Wrap (
    des_cblock	        input,
    des_cblock          key,
    des_cblock          output,
    int			bytes)
{
    int			i, j;
    int			len;
    des_cblock          tmp;
    des_cblock          expand_key;
    des_key_schedule	schedule;

    XCBDESKeyToOddParity (key, expand_key);
    XCBDESKeySchedule (expand_key, schedule);
    for (j = 0; j < bytes; j += 8)
    {
	len = 8;
	if (bytes - j < len)
	    len = bytes - j;
	/* block chaining */
	for (i = 0; i < len; i++)
	{
	    if (j == 0)
		tmp[i] = input[i];
	    else
		tmp[i] = input[j + i] ^ output[j - 8 + i];
	}
	for (; i < 8; i++)
	{
	    if (j == 0)
		tmp[i] = 0;
	    else
		tmp[i] = 0 ^ output[j - 8 + i];
	}
	XCBDESEncrypt (tmp, (output + j), schedule, 1);
    }
}

#endif

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
    int authnamelens[N_AUTH_PROTOS];
    int i;


    if (getpeername(fd, (struct sockaddr *) sockname, &socknamelen) == -1)
        return 0;  /* can only authenticate sockets */
    family = FamilyLocal; /* 256 */
    switch (sockname->sa_family) {
    case AF_INET:
	/*block*/ {
             struct sockaddr_in *si = (struct sockaddr_in *) sockname;
	     assert(sizeof(*si) == socknamelen);
	     addr = (char *) &si->sin_addr;
	     addrlen = 4;
	     family = FamilyInternet; /* 0 */
	     if (ntohl(si->sin_addr.s_addr) == 0x7f000001)
		 family = FamilyLocal; /* 256 */
	     (void) sprintf(dispbuf, "%d", ntohs(si->sin_port) - X_TCP_PORT);
	     display = dispbuf;
        }
	break;
    case AF_UNIX:
	/*block*/ { 
	    struct sockaddr_un *su = (struct sockaddr_un *) sockname;
	    assert(sizeof(*su) >= socknamelen);
	    display = strrchr(su->sun_path, 'X');
	    if (display == 0)
		return 0;   /* sockname is mangled somehow */
	    display++;
	}
	break;
    default:
        return 0;   /* cannot authenticate this family */
    }
    if (family == FamilyLocal) {
        if (gethostname(hostnamebuf, sizeof(hostnamebuf)) == -1)
            return 0;   /* do not know own hostname */
        addr = hostnamebuf;
        addrlen = strlen(addr);
    }
    for (i = 0; i < N_AUTH_PROTOS; i++)
	authnamelens[i] = strlen(authnames[i]);
    authptr = XauGetBestAuthByAddr (family,
                                    (unsigned short) addrlen, addr,
                                    (unsigned short) strlen(display), display,
                                    N_AUTH_PROTOS, authnames, authnamelens);
    if (authptr == 0)
        return 0;   /* cannot find good auth data */
    if (strlen(authnames[AUTH_MC1]) == authptr->name_length &&
        !memcmp(authnames[AUTH_MC1], authptr->name, authptr->name_length)) {
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
#ifdef HAS_AUTH_XA1
    if (strlen(authnames[AUTH_MC1]) == authptr->name_length &&
        !memcmp(authnames[AUTH_MC1], authptr->name, authptr->name_length)) {
        int j;
        long now;

        (void)memcpy(info->name,
                     authptr->name,
                     authptr->name_length);
        info->namelen = authptr->name_length;
        for (j = 0; j < 8; j++)
            info->data[j] = authptr->data[j];
	switch(sockname->sa_family) {
        case AF_INET:
	    /*block*/ {
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
	    }
	    break;
        case AF_UNIX:
	    /*block*/ {
		long fakeaddr = htonl(0xffffffff - nonce);
		short fakeport = htons(getpid());
		(void)memcpy(info->data + j, &fakeaddr, sizeof(long));
		j += sizeof(long);
		(void)memcpy(info->data + j, &fakeport, sizeof(short));
		j += sizeof(short);
	    }
	    break;
        default:
	    XauDisposeAuth(authptr);
            return 0;   /* do not know how to build this */
        }
        (void)time(&now);
        now = htonl(now);
        memcpy(info->data + j, &now, sizeof(long));
        j += sizeof(long);
        while (j < 192 / 8)
            info->data[j++] = 0;
        info->datalen = j;
	Wrap (info->data, authptr->data + 8, info->data, info->datalen);
	XauDisposeAuth(authptr);
        return info;
    }
#endif
    XauDisposeAuth(authptr);
    return 0;   /* Unknown authorization type */
}
