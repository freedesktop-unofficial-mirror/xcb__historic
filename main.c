#include <stdio.h>
#include <unistd.h>

#include "xp_core.h"

#define InputOutput 1

int main(void)
{
    int fd;
    XCB_Connection *c;
    XP_CreateWindowValues values = { /* mask */ 0 };

    fd = XCB_Open_TCP("localhost", 6010);
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

    XP_CreateWindow(c, /* depth */ 16,
        /* seems like this is guaranteed to be a valid window id :-) */
        c->disp_info.resource_id_mask | c->disp_info.resource_id_base,
        c->disp_info.roots[0].root,
        /* x */ 300, /* y */ 200, /* width */ 100, /* height */ 300,
        /* border_width */ 10, /* class */ InputOutput,
        /* visual */ c->disp_info.roots[0].root_visual, values);
    sleep(10);
    exit(0);
    /*NOTREACHED*/
}
