#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include "xp_core.h"

#undef USE_TCP

#define InputOutput 1

int main(int argc, char **argv)
{
    int fd;
    XCB_Connection *c;
    XP_CreateWindowValues values = { /* mask */ 0 };
    XP_WINDOW wid;

#ifdef USE_TCP
    if(argc != 3)
    {
        printf("Usage: %s <host> <port>\n", argv[0]);
        exit(1);
    }
    fd = XCB_Open_TCP(argv[1], atoi(argv[2]));
#else
    if(argc != 2)
    {
        printf("Usage: %s <filename>\n", argv[0]);
        exit(1);
    }
    fd = XCB_Open_Unix(argv[1]);
#endif

    if(fd == -1)
    {
        perror("XCB_Open_TCP");
        abort();
    }
    c = XCB_Connect(fd);
    if(!c)
    {
        printf("Failed to connect to localhost:6010!\n");
        abort();
    }

    /* seems like this is guaranteed to be a valid window id :-) */
    wid = c->disp_info.resource_id_mask | c->disp_info.resource_id_base;

    XP_CreateWindow(c, /* depth */ 16, wid, c->disp_info.roots[0].root,
        /* x */ 300, /* y */ 200, /* width */ 100, /* height */ 300,
        /* border_width */ 10, /* class */ InputOutput,
        /* visual */ c->disp_info.roots[0].root_visual, values);
    XP_MapWindow(c, wid);
		XP_Flush(c);
    sleep(10);
    exit(0);
    /*NOTREACHED*/
}
